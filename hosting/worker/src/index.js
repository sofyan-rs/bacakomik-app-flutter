// Cloudflare Worker for bacakomik.kurodev.org, the host of shared links
// (https://bacakomik.kurodev.org/series/<slug>).
//
// - /.well-known/assetlinks.json lets Android verify the App Link, so the
//   link opens BacaKomik directly when it is installed.
// - /series/<slug> is the fallback page when it is not (or when the link
//   is opened in a browser). It carries Open Graph tags with the series
//   title, cover and synopsis so chat apps show a preview.

const PACKAGE = 'org.kurodev.bacakomik';

// SHA-256 of the release (upload) signing key. Regenerate with
// `keytool -list -v -keystore <keystore.jks> -alias upload` if it changes.
const FINGERPRINTS = [
  '19:A5:96:D5:58:7F:8D:33:73:A2:78:60:66:A1:E3:5B:8A:48:37:F2:F2:3E:0C:D3:49:30:74:5E:1B:69:D0:E7',
];

const API = 'https://api-bacakomik.kurodev.org';
const DOWNLOAD =
  'https://github.com/sofyan-rs/bacakomik-app-flutter/releases/latest';
const APP_NAME = 'BacaKomik';

// Series pages are cached at the edge for this long, in seconds.
const PAGE_TTL = 60 * 60;

export default {
  async fetch(request, env, ctx) {
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response(null, {
        status: 405,
        headers: { Allow: 'GET, HEAD' },
      });
    }
    const url = new URL(request.url);
    if (url.pathname === '/.well-known/assetlinks.json') return assetLinks();

    const match = url.pathname.match(/^\/series\/([a-z0-9-]+)\/?$/i);
    if (match) return cached(request, ctx, () => seriesPage(match[1], url));

    if (url.pathname === '/') return html(page({ url: `${url.origin}/` }));
    return html(page({ url: url.href, missing: true }), 404);
  },
};

function assetLinks() {
  const body = [
    {
      relation: ['delegate_permission/common.handle_all_urls'],
      target: {
        namespace: 'android_app',
        package_name: PACKAGE,
        sha256_cert_fingerprints: FINGERPRINTS,
      },
    },
  ];
  return new Response(JSON.stringify(body, null, 2), {
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'public, max-age=3600',
    },
  });
}

// Serves `build()` from the edge cache, keyed without the query string
// (chat apps add tracking parameters).
async function cached(request, ctx, build) {
  const cache = globalThis.caches?.default;
  const key = new URL(request.url);
  key.search = '';
  const keyRequest = new Request(key.href, { method: 'GET' });

  const hit = await cache?.match(keyRequest);
  if (hit) return hit;

  const response = await build();
  if (cache && response.status === 200 && response.headers.get('Cache-Control') !== 'no-store') {
    ctx.waitUntil(cache.put(keyRequest, response.clone()));
  }
  return response;
}

async function seriesPage(slug, url) {
  const link = `${url.origin}/series/${slug}`;
  let series = null;
  try {
    const res = await fetch(`${API}/series/${slug}`, {
      cf: { cacheTtl: PAGE_TTL, cacheEverything: true },
    });
    if (res.status === 404) {
      return html(page({ url: link, missing: true }), 404);
    }
    if (res.ok) series = (await res.json()).data ?? null;
  } catch {
    // API down: still serve the page so the link can open the app.
  }

  const response = html(
    page({
      url: link,
      title: series?.title ?? titleFromSlug(slug),
      description: series?.synopsis,
      image: series?.cover,
      meta:
        series &&
        [series.format, series.status, series.releaseDate]
          .filter(Boolean)
          .join(' · '),
    }),
  );
  // Without the details, ask the API again on the next visit.
  if (!series) response.headers.set('Cache-Control', 'no-store');
  return response;
}

// `magic-emperor` → `Magic Emperor`, the same placeholder as the app.
export function titleFromSlug(slug) {
  return slug
    .split('-')
    .filter(Boolean)
    .map((w) => w[0].toUpperCase() + w.slice(1))
    .join(' ');
}

function html(body, status = 200) {
  return new Response(body, {
    status,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': `public, max-age=${PAGE_TTL}`,
    },
  });
}

const ENTITIES = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;',
};
const escape = (s) => String(s).replace(/[&<>"']/g, (c) => ENTITIES[c]);

function clip(text, max) {
  const t = String(text).replace(/\s+/g, ' ').trim();
  return t.length > max ? `${t.slice(0, max - 1).trimEnd()}…` : t;
}

// Opens the app when installed, else the download page (Chrome on Android).
function intentLink(url) {
  const u = new URL(url);
  return (
    `intent://${u.host}${u.pathname}#Intent;scheme=https;package=${PACKAGE};` +
    `S.browser_fallback_url=${encodeURIComponent(DOWNLOAD)};end`
  );
}

export function page({ url, title, description, image, meta, missing = false }) {
  const heading = missing ? 'Series tidak ditemukan' : (title ?? APP_NAME);
  const docTitle = title ? `${title} — ${APP_NAME}` : APP_NAME;
  const desc = description
    ? clip(description, 200)
    : missing
      ? 'Link ini tidak mengarah ke series yang ada.'
      : `Baca komik di aplikasi ${APP_NAME}.`;
  const og = [
    ['og:site_name', APP_NAME],
    ['og:type', 'website'],
    ['og:url', url],
    ['og:title', docTitle],
    ['og:description', desc],
    ...(image ? [['og:image', image]] : []),
  ]
    .map(([p, c]) => `<meta property="${p}" content="${escape(c)}">`)
    .join('\n  ');

  return `<!doctype html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escape(docTitle)}</title>
  <meta name="description" content="${escape(desc)}">
  ${og}
  <meta name="twitter:card" content="${image ? 'summary_large_image' : 'summary'}">
  <style>
    body { margin: 0; min-height: 100vh; display: grid; place-items: center;
      background: #000; color: #fff; font-family: system-ui, sans-serif;
      text-align: center; }
    main { padding: 24px; max-width: 360px; }
    img { width: 200px; aspect-ratio: 2 / 3; object-fit: cover;
      border-radius: 16px; }
    .brand { font-size: 13px; letter-spacing: 0.2em; color: #9a9a9a;
      margin: 0 0 24px; }
    .meta { font-size: 12px; letter-spacing: 0.15em; color: #9a9a9a;
      text-transform: uppercase; margin-top: 16px; }
    h1 { font-size: 26px; font-weight: 500; margin: 12px 0; }
    p { color: #9a9a9a; line-height: 1.5; margin: 0 0 24px; }
    a { display: block; padding: 16px; border-radius: 999px;
      text-decoration: none; font-weight: 600; margin-bottom: 12px; }
    .primary { background: #fff; color: #000; }
    .secondary { border: 1px solid #444; color: #fff; }
  </style>
</head>
<body>
  <main>
    <p class="brand">BACAKOMIK</p>
    ${image ? `<img src="${escape(image)}" alt="">` : ''}
    ${meta ? `<div class="meta">${escape(meta)}</div>` : ''}
    <h1>${escape(heading)}</h1>
    <p>${escape(desc)}</p>
    ${missing ? '' : `<a class="primary" href="${escape(intentLink(url))}">Buka di aplikasi</a>`}
    <a class="secondary" href="${DOWNLOAD}">Download APK</a>
  </main>
</body>
</html>`;
}
