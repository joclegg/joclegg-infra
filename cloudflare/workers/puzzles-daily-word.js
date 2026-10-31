// Serves the Five Letters "Daily puzzle 2" word for a day:
//   GET /word/2026-10-31 -> {"date":"2026-10-31","word":"slate"}
// It reads the word from a public answers page and keeps each day's word in
// Cloudflare's cache, so the source is asked at most about once a day per
// data centre. A day the source doesn't list yet is a 404.

const SOURCE_URL = "https://word.tips/todays-wordle-answer/";
const DAY = /^\/word\/(\d{4}-\d{2}-\d{2})$/;
const ENTRY = /date:"(\d{4}-\d{2}-\d{2})",number:\d+,answer:"([A-Za-z]{5})"/g;
const ONE_DAY = 24 * 60 * 60 * 1000;
const HEADERS = {
  "access-control-allow-origin": "*",
  "content-type": "application/json",
};

function reply(status, body, maxAge) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...HEADERS, "cache-control": `public, max-age=${maxAge}` },
  });
}

export function readWords(html) {
  const words = new Map();
  for (const [, date, word] of html.matchAll(ENTRY)) {
    words.set(date, word.toLowerCase());
  }
  return words;
}

export default {
  async fetch(request, _env, ctx) {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: { ...HEADERS, "access-control-allow-methods": "GET" },
      });
    }
    const url = new URL(request.url);
    const match = DAY.exec(url.pathname);
    if (request.method !== "GET" || !match) {
      return reply(404, { error: "not found" }, 300);
    }
    const date = match[1];
    // No day later than tomorrow in UTC: nowhere on Earth has reached it.
    if (Date.parse(date) > Date.now() + ONE_DAY) {
      return reply(404, { error: "not found" }, 300);
    }

    const cache = caches.default;
    const key = new Request(`${url.origin}/word/${date}`);
    const cached = await cache.match(key);
    if (cached) {
      return cached;
    }

    const source = await fetch(SOURCE_URL, {
      headers: { "user-agent": "Mozilla/5.0 (puzzles-daily-word)" },
    });
    if (!source.ok) {
      return reply(502, { error: "source unavailable" }, 0);
    }
    const word = readWords(await source.text()).get(date);
    if (!word) {
      return reply(404, { error: "not found" }, 300);
    }
    const response = reply(200, { date, word }, 86400);
    ctx.waitUntil(cache.put(key, response.clone()));
    return response;
  },
};
