// Cloudflare Worker for bacakomik.kurodev.org, the host of shared links
// (https://bacakomik.kurodev.org/series/<slug>).
//
// - /.well-known/assetlinks.json lets Android verify the App Link, so the
//   link opens BacaKomik directly when it is installed.
// - /series/<key> is the fallback page when it is not (or when the link
//   is opened in a browser). <key> is a slug for the default BacaKomik
//   source, which gets Open Graph tags with the series title, cover and
//   synopsis so chat apps show a preview; other sources' comics are
//   `<source>:<slug>` and only get a title made from the slug.
// - / is the app's home page (what the app does, download, privacy link),
//   also the homepage URL of the Google sign-in consent screen.
// - /privacy-policy is the privacy policy, linked from the Google sign-in consent
//   screen used by Drive sync.

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
const ISSUES =
  'https://github.com/sofyan-rs/bacakomik-app-flutter/issues/new';

// Shown on the privacy page. Bump when the policy text changes.
const PRIVACY_UPDATED = '25 October 2026';

// Display names of the extension sources the app ships; others show their id.
const SOURCE_NAMES = { voratoon: 'VoraToon' };

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

    // Some apps percent-encode the `:` of `<source>:<slug>`.
    const match = decodeURIComponent(url.pathname).match(
      /^\/series\/(?:([a-z0-9][a-z0-9_-]*):)?([a-z0-9-]+)\/?$/i,
    );
    if (match) {
      const [, source, slug] = match;
      return cached(request, ctx, () =>
        source ? otherSourcePage(source, slug, url) : seriesPage(slug, url),
      );
    }

    if (/^\/privacy(-policy)?\/?$/.test(url.pathname)) {
      return html(privacyPage());
    }
    if (url.pathname === '/') return html(homePage(url.origin));
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

// A comic from another source: the API only knows BacaKomik's, so the page
// has a title from the slug and the source name.
function otherSourcePage(source, slug, url) {
  return html(
    page({
      url: `${url.origin}/series/${source}:${slug}`,
      title: titleFromSlug(slug),
      meta: SOURCE_NAMES[source] ?? source,
    }),
  );
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
  const heading = missing ? 'Series not found' : (title ?? APP_NAME);
  const docTitle = title ? `${title} — ${APP_NAME}` : APP_NAME;
  const desc = description
    ? clip(description, 200)
    : missing
      ? 'This link does not point to an existing series.'
      : `Read comics in the ${APP_NAME} app.`;
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
<html lang="en">
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
    ${missing ? '' : `<a class="primary" href="${escape(intentLink(url))}">Open in the app</a>`}
    <a class="secondary" href="${DOWNLOAD}">Download APK</a>
  </main>
</body>
</html>`;
}

export function privacyPage() {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Privacy Policy — ${APP_NAME}</title>
  <meta name="description" content="What data ${APP_NAME} stores and where it is sent.">
  <style>
    body { margin: 0; background: #000; color: #fff;
      font-family: system-ui, sans-serif; line-height: 1.6; }
    main { padding: 32px 24px 48px; max-width: 640px; margin: 0 auto; }
    .brand { font-size: 13px; letter-spacing: 0.2em; color: #9a9a9a; }
    h1 { font-size: 28px; font-weight: 500; margin: 8px 0 4px; }
    h2 { font-size: 18px; font-weight: 600; margin: 32px 0 8px; }
    p, li { color: #cfcfcf; }
    .updated { color: #9a9a9a; font-size: 14px; margin-top: 0; }
    a { color: #fff; }
    code { background: #1a1a1a; padding: 1px 6px; border-radius: 6px; }
  </style>
</head>
<body>
  <main>
    <p class="brand">BACAKOMIK</p>
    <h1>Privacy Policy</h1>
    <p class="updated">Last updated ${PRIVACY_UPDATED}</p>

    <p>${APP_NAME} is an Android app for reading comics, made by Kurodev.
    This page explains what data the app uses and where that data is
    sent.</p>

    <h2>Data on your device</h2>
    <p>Bookmarks, categories, reading history (the last chapter and page),
    settings, installed extensions and downloaded chapters are kept in the
    app's storage on your device. This data is not sent to our servers.</p>

    <h2>Comic content and sources</h2>
    <p>Comic lists, details and chapter pages come from the source you pick.
    The bundled BacaKomik source reads from our server
    <code>api-bacakomik.kurodev.org</code>. Other sources are extensions:
    small scripts the app installs from an extension repo (by default
    <code>bacakomik-ext.kurodev.org</code>, or a repo you add) and that
    connect directly to the comic site they read. These requests do not carry
    your Google account, bookmarks or reading history. Like any web server,
    our server and the comic sites can log your IP address and the time of a
    request for technical purposes. Extensions from repos you add yourself
    are not made or checked by us, so only add repos you trust.</p>
    <p>When a site asks for a bot check, the app opens it in a built-in
    WebView and keeps the cookies that site sets, so the next requests to that
    site pass. You can clear these cookies from the WebView menu.</p>

    <h2>Google Drive sync (optional)</h2>
    <p>If you turn on sync, the app asks you to sign in with Google with
    <code>drive.appdata</code> access. This access only opens a hidden app
    data folder in your Google Drive, not your other Drive files.</p>
    <ul>
      <li>What is stored in that folder: your bookmarks, categories, reading
      history and a record of items you deleted, in one file.</li>
      <li>Your Google account email address is used to show the connected
      account in the app.</li>
      <li>Data is sent directly between your device and Google. We do not
      receive, store or share it.</li>
      <li>You can turn off sync at any time in the More menu, and revoke the
      app's access in your
      <a href="https://myaccount.google.com/permissions">Google account
      settings</a>. The data in Drive can be deleted from Google Drive →
      Settings → Manage apps.</li>
    </ul>
    <p>Use of data from Google APIs follows the
    <a href="https://developers.google.com/terms/api-services-user-data-policy">Google
    API Services User Data Policy</a>, including the Limited Use
    requirements.</p>

    <h2>Backups and imports</h2>
    <p>Backup files, Mihon / Tachiyomi backups and Comix.to exports are read
    and written on your device only. A file leaves your device only if you
    share or move it yourself.</p>

    <h2>App updates</h2>
    <p>The app checks for new versions and downloads them from GitHub. These
    requests do not carry personal data.</p>

    <h2>Ads and tracking</h2>
    <p>${APP_NAME} has no ads, analytics or third-party trackers.</p>

    <h2>Contact</h2>
    <p>Questions about privacy can be sent through
    <a href="${ISSUES}">GitHub Issues</a>.</p>
  </main>
</body>
</html>`;
}

export function homePage(origin) {
  const desc =
    'An Android app for reading manga, manhwa and manhua from several sources.';
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${APP_NAME} — Read comics on Android</title>
  <meta name="description" content="${escape(desc)}">
  <meta property="og:site_name" content="${APP_NAME}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="${escape(`${origin}/`)}">
  <meta property="og:title" content="${APP_NAME}">
  <meta property="og:description" content="${escape(desc)}">
  <style>
    body { margin: 0; background: #000; color: #fff;
      font-family: system-ui, sans-serif; line-height: 1.6; }
    main { padding: 48px 24px; max-width: 560px; margin: 0 auto; }
    .brand { font-size: 13px; letter-spacing: 0.2em; color: #9a9a9a; }
    h1 { font-size: 32px; font-weight: 500; margin: 8px 0 12px; }
    h2 { font-size: 18px; font-weight: 600; margin: 32px 0 8px; }
    p, li { color: #cfcfcf; }
    ul { padding-left: 20px; }
    .button { display: block; padding: 16px; border-radius: 999px;
      text-align: center; text-decoration: none; font-weight: 600;
      background: #fff; color: #000; margin: 24px 0 12px; }
    footer { margin-top: 40px; font-size: 14px; color: #9a9a9a; }
    footer a { color: #fff; margin-right: 16px; }
  </style>
</head>
<body>
  <main>
    <p class="brand">BACAKOMIK</p>
    <h1>${APP_NAME}</h1>
    <p>${escape(desc)} Free, without ads, made by Kurodev.</p>
    <a class="button" href="${DOWNLOAD}">Download APK</a>

    <h2>Features</h2>
    <ul>
      <li>Several sources: BacaKomik and VoraToon come bundled, and more
      install as extensions, so new sites can be added without an app
      update.</li>
      <li>Browse the latest and popular comics, search by title and filter by
      the source's own genres, type and status.</li>
      <li>A reader with a vertical strip or page by page, zoom, auto-scroll,
      and resume at the page you stopped at.</li>
      <li>Bookmarks with your own categories and new chapter badges, and a
      reading history that keeps the last page.</li>
      <li>Download chapters to read offline.</li>
      <li>Move your library to another source, or import it from a Mihon /
      Tachiyomi backup or a Comix.to export.</li>
      <li>Sync bookmarks, categories and reading history across devices
      through Google Drive (optional). Data is kept in a hidden app folder in
      your own Drive; the app cannot see your other Drive files.</li>
      <li>Back up and restore your library to a file.</li>
    </ul>

    <h2>Privacy</h2>
    <p>Bookmarks, history and downloads stay on your device. When sync is
    on, data is only sent between your device and Google Drive. Read more in
    the <a href="/privacy-policy">Privacy Policy</a>.</p>

    <footer>
      <a href="/privacy-policy">Privacy Policy</a>
      <a href="https://github.com/sofyan-rs/bacakomik-app-flutter">GitHub</a>
      <a href="${ISSUES}">Contact</a>
    </footer>
  </main>
</body>
</html>`;
}
