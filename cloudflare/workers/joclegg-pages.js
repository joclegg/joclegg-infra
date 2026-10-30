// Serves GitHub Pages sites at joclegg.dev addresses, leaving their
// joclegg.github.io addresses as they are. Each hostname maps to a path on
// joclegg.github.io. Paths that already start with it pass through unchanged,
// so the sites' own links to /cv/... or /puzzles-web/... keep working.
const ORIGIN = "https://joclegg.github.io";

const SITES = {
  "joclegg.dev": "/cv",
  "puzzles.joclegg.dev": "/puzzles-web",
};

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const prefix = SITES[url.hostname];
    if (!prefix) {
      return new Response("Not found", { status: 404 });
    }

    const path =
      url.pathname === prefix || url.pathname.startsWith(`${prefix}/`)
        ? url.pathname
        : `${prefix}${url.pathname}`;
    const response = await fetch(`${ORIGIN}${path}${url.search}`, {
      method: request.method,
      headers: request.headers,
      redirect: "manual",
    });

    // GitHub redirects folders without a trailing slash to joclegg.github.io:
    // send those back to this hostname instead.
    const target = (response.headers.get("location") ?? "").match(
      /^https?:\/\/joclegg\.github\.io(\/.*)$/,
    )?.[1];
    if (!target?.startsWith(`${prefix}/`)) {
      return response;
    }
    const rewritten = new Response(response.body, response);
    rewritten.headers.set(
      "location",
      `https://${url.hostname}${target.slice(prefix.length)}`,
    );
    return rewritten;
  },
};
