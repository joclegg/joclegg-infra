// Receives push webhooks from the repositories listed in github/webhooks.tf and
// sends a repository_dispatch to each target when their main branch moves.
const TARGETS = [{ repository: "joclegg/puzzles", event: "submodule-merged" }];
const MAIN = "refs/heads/main";
const API = "https://api.github.com";
const encoder = new TextEncoder();

export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }
    const body = await request.text();
    const signature = request.headers.get("x-hub-signature-256") ?? "";
    if (!(await isSigned(body, signature, env.WEBHOOK_SECRET))) {
      return new Response("Bad signature", { status: 401 });
    }
    if (request.headers.get("x-github-event") !== "push") {
      return new Response("Ignored", { status: 202 });
    }
    if (JSON.parse(body).ref !== MAIN) {
      return new Response("Ignored", { status: 202 });
    }
    for (const { repository, event } of TARGETS) {
      await dispatch(repository, event, env);
    }
    return new Response("Sent", { status: 200 });
  },
};

async function isSigned(body, signature, secret) {
  const match = signature.match(/^sha256=([0-9a-f]{64})$/);
  if (!match) {
    return false;
  }
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const bytes = Uint8Array.from(match[1].match(/../g), (it) => parseInt(it, 16));
  return crypto.subtle.verify("HMAC", key, bytes, encoder.encode(body));
}

async function dispatch(repository, event, env) {
  const jwt = await appJwt(env);
  const { id } = await github(`/repos/${repository}/installation`, jwt);
  const { token } = await github(`/app/installations/${id}/access_tokens`, jwt, {});
  await github(`/repos/${repository}/dispatches`, token, { event_type: event });
}

async function github(path, token, body) {
  const response = await fetch(`${API}${path}`, {
    method: body ? "POST" : "GET",
    headers: {
      accept: "application/vnd.github+json",
      authorization: `Bearer ${token}`,
      "user-agent": "joclegg-merge-webhook",
    },
    body: body && JSON.stringify(body),
  });
  if (!response.ok) {
    throw new Error(`${path} returned ${response.status}`);
  }
  return response.status === 204 ? null : response.json();
}

async function appJwt(env) {
  const now = Math.floor(Date.now() / 1000);
  const claims = { iat: now - 60, exp: now + 300, iss: env.APP_CLIENT_ID };
  const unsigned = `${base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }))}.${base64Url(JSON.stringify(claims))}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pkcs8(env.APP_PRIVATE_KEY),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, encoder.encode(unsigned));
  return `${unsigned}.${base64Url(new Uint8Array(signature))}`;
}

function base64Url(value) {
  const bytes = typeof value === "string" ? encoder.encode(value) : value;
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

// GitHub Apps' keys are PKCS#1, and Web Crypto only imports PKCS#8.
function pkcs8(pem) {
  const der = Uint8Array.from(atob(pem.replace(/-----[^-]+-----|\s/g, "")), (it) => it.charCodeAt(0));
  if (pem.includes("BEGIN PRIVATE KEY")) {
    return der;
  }
  const rsaEncryption = [0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00];
  const inner = [0x02, 0x01, 0x00, ...rsaEncryption, ...derHeader(0x04, der.length), ...der];
  return new Uint8Array([...derHeader(0x30, inner.length), ...inner]);
}

function derHeader(tag, length) {
  return length < 128 ? [tag, length] : [tag, 0x82, length >> 8, length & 0xff];
}
