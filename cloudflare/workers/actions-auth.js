// Finishes "Sign in with GitHub" for actions-dashboard. GitHub's token
// endpoint needs the app's client secret and doesn't answer browsers, so the
// page sends the code (or a refresh token) here and gets GitHub's reply back.
// Nothing is stored or logged.
const ALLOWED_ORIGINS = new Set([
  "https://actions.joclegg.dev",
  "https://joclegg.github.io",
  "http://localhost:5173",
  "http://localhost:4173",
]);

export default {
  async fetch(request, env) {
    const origin = request.headers.get("origin") ?? "";
    const cors = ALLOWED_ORIGINS.has(origin)
      ? {
          "access-control-allow-origin": origin,
          "access-control-allow-methods": "POST",
          "access-control-allow-headers": "content-type",
          "access-control-max-age": "86400",
          vary: "origin",
        }
      : {};

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors });
    }
    const url = new URL(request.url);
    if (request.method !== "POST" || url.pathname !== "/token") {
      return new Response("Not found", { status: 404, headers: cors });
    }
    if (!ALLOWED_ORIGINS.has(origin)) {
      return new Response("Forbidden", { status: 403 });
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "bad_request" }, 400, cors);
    }
    const params = new URLSearchParams({
      client_id: env.CLIENT_ID,
      client_secret: env.CLIENT_SECRET,
    });
    if (typeof body.code === "string") {
      params.set("code", body.code);
      if (typeof body.redirect_uri === "string") {
        params.set("redirect_uri", body.redirect_uri);
      }
    } else if (typeof body.refresh_token === "string") {
      params.set("grant_type", "refresh_token");
      params.set("refresh_token", body.refresh_token);
    } else {
      return json({ error: "bad_request" }, 400, cors);
    }

    const response = await fetch("https://github.com/login/oauth/access_token", {
      method: "POST",
      headers: {
        accept: "application/json",
        "content-type": "application/x-www-form-urlencoded",
      },
      body: params,
    });
    const result = await response.json();
    if (!result.access_token) {
      return json({ error: result.error ?? "exchange_failed" }, 400, cors);
    }
    return json(
      {
        access_token: result.access_token,
        expires_in: result.expires_in,
        refresh_token: result.refresh_token,
      },
      200,
      cors,
    );
  },
};

function json(value, status, headers) {
  return new Response(JSON.stringify(value), {
    status,
    headers: { ...headers, "content-type": "application/json", "cache-control": "no-store" },
  });
}
