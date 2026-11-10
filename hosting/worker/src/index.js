// Cloudflare Worker for yoru.kurodev.org, the host of shared links
// (https://yoru.kurodev.org/series/<slug>). It serves bacakomik.kurodev.org,
// the host from before the rename to Yoru, the same way.
//
// - /.well-known/assetlinks.json lets Android verify the App Link, so the
//   link opens Yoru directly when it is installed.
// - /series/<key> is the fallback page when it is not (or when the link
//   is opened in a browser). <key> is a slug for the default BacaKomik
//   source, which gets Open Graph tags with the series title, cover and
//   synopsis so chat apps show a preview; other sources' comics are
//   `<source>:<slug>` and only get a title made from the slug.
// - / is the app's home page (what the app does, download, privacy link),
//   also the homepage URL of the Google sign-in consent screen.
// - /privacy-policy is the privacy policy, linked from the Google sign-in consent
//   screen used by Drive sync.

import { appleTouch, favicon32, favicon64 } from './icons.js';

const PACKAGE = 'org.kurodev.yoru';
// The app's id before it was renamed to Yoru (2.17.0). Installs that were
// not moved over yet still open links.
const OLD_PACKAGE = 'org.kurodev.bacakomik';

// SHA-256 of the release (upload) signing key. Regenerate with
// `keytool -list -v -keystore <keystore.jks> -alias upload` if it changes.
const FINGERPRINTS = [
  '19:A5:96:D5:58:7F:8D:33:73:A2:78:60:66:A1:E3:5B:8A:48:37:F2:F2:3E:0C:D3:49:30:74:5E:1B:69:D0:E7',
];

const API = 'https://api-bacakomik.kurodev.org';
const DOWNLOAD =
  'https://github.com/sofyan-rs/yoru-comic-app/releases/latest';
const APP_NAME = 'Yoru';
const ISSUES =
  'https://github.com/sofyan-rs/yoru-comic-app/issues/new';

// Shown on the privacy page. Bump when the policy text changes.
const PRIVACY_UPDATED = '10 November 2026';

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
    const iconFile = ICON_FILES[url.pathname];
    if (iconFile) return png(iconFile);

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

// Favicon paths. /favicon.ico is asked for by browsers that ignore the
// <link> tags; it is served as PNG, which they all read.
const ICON_FILES = {
  '/favicon.ico': favicon32,
  '/favicon-32.png': favicon32,
  '/favicon-64.png': favicon64,
  '/apple-touch-icon.png': appleTouch,
};

function png(base64) {
  const bytes = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
  return new Response(bytes, {
    headers: {
      'Content-Type': 'image/png',
      'Cache-Control': 'public, max-age=604800',
    },
  });
}

function assetLinks() {
  const body = [PACKAGE, OLD_PACKAGE].map((packageName) => ({
    relation: ['delegate_permission/common.handle_all_urls'],
    target: {
      namespace: 'android_app',
      package_name: packageName,
      sha256_cert_fingerprints: FINGERPRINTS,
    },
  }));
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

const GITHUB = 'https://github.com/sofyan-rs/yoru-comic-app';
const KURODEV = 'https://kurodev.org';
const SCREENSHOT = (name) =>
  `https://raw.githubusercontent.com/sofyan-rs/yoru-comic-app/main/screenshot/${name}.png`;

// Dotline, the design system of kurodev.org: monochrome, dark first, one red
// signal colour, Doto dot-matrix display type, Geist Mono labels, pills and
// hairlines. Light theme follows the system setting.
const STYLE = `
    :root { --bg: #000; --surface: #111; --raised: #1c1c1c;
      --line: rgb(255 255 255 / 0.12); --line-strong: #4a4a4a; --ink: #fff;
      --muted: #a6a6a6; --faint: #808080; --on-ink: #000; --accent: #e5211c;
      --accent-text: #ff5a52; --positive: #4ad991; color-scheme: dark;
      --dot: "Doto", ui-monospace, monospace;
      --sans: "Geist", ui-sans-serif, system-ui, sans-serif;
      --mono: "Geist Mono", ui-monospace, monospace; }
    @media (prefers-color-scheme: light) {
      :root { --bg: #f2f2f2; --surface: #fff; --raised: #e8e8e8;
        --line: rgb(0 0 0 / 0.1); --line-strong: #bdbdbd; --ink: #000;
        --muted: #4d4d4d; --faint: #6b6b6b; --on-ink: #fff; --accent: #d70015;
        --accent-text: #d70015; --positive: #0b6b3c; color-scheme: light; }
    }
    * { box-sizing: border-box; }
    html { background: var(--bg); color: var(--ink); font-family: var(--sans);
      -webkit-font-smoothing: antialiased; }
    body { margin: 0; font-size: 15px; line-height: 22px; }
    ::selection { background: var(--ink); color: var(--on-ink); }
    :focus-visible { outline: 2px solid var(--ink); outline-offset: 2px; }
    a { color: inherit; }
    img { display: block; max-width: 100%; }
    .wrap { max-width: 1040px; margin: 0 auto; padding: 0 16px; }
    @media (min-width: 640px) { .wrap { padding: 0 24px; } }
    .label { font-family: var(--mono); font-size: 11px; line-height: 14px;
      letter-spacing: 0.12em; text-transform: uppercase; }
    .data { font-family: var(--mono); font-size: 13px; line-height: 18px; }
    .muted { color: var(--muted); }
    .faint { color: var(--faint); }
    .status { display: inline-block; width: 6px; height: 6px;
      border-radius: 50%; background: var(--accent); flex: none; }
    .status.ok { background: var(--positive); }
    .pulse { animation: pulse 2s ease-in-out infinite; }
    @keyframes pulse { 50% { opacity: 0.35; } }
    .dot-grid { position: absolute; inset: 0; pointer-events: none;
      opacity: 0.6;
      background-image: radial-gradient(var(--line-strong) 1px, transparent 1.5px);
      background-size: 8px 8px;
      -webkit-mask-image: radial-gradient(ellipse 70% 60% at 70% 40%, #000, transparent);
      mask-image: radial-gradient(ellipse 70% 60% at 70% 40%, #000, transparent); }

    header.top { position: sticky; top: 0; z-index: 10;
      border-bottom: 1px solid var(--line);
      background: color-mix(in srgb, var(--bg) 80%, transparent);
      -webkit-backdrop-filter: blur(12px); backdrop-filter: blur(12px); }
    header.top .wrap { display: flex; align-items: center;
      justify-content: space-between; height: 64px; gap: 16px; }
    .brand { display: flex; align-items: center; gap: 8px;
      text-decoration: none; font-family: var(--dot); font-weight: 900;
      font-size: 24px; line-height: 1; letter-spacing: -0.01em; }
    nav { display: flex; gap: 4px; }
    nav a { display: inline-flex; align-items: center; gap: 6px; height: 40px;
      padding: 0 12px; border-radius: 999px; text-decoration: none;
      color: var(--muted); transition: color 0.15s; }
    nav a:hover { color: var(--ink); }

    .icon { width: 1.15em; height: 1.15em; flex: none; vertical-align: -0.2em; }
    .btn { display: inline-flex; align-items: center; justify-content: center;
      gap: 8px; height: 48px; padding: 0 24px; border-radius: 999px;
      font-weight: 500; text-decoration: none;
      transition: opacity 0.15s, background-color 0.15s; }
    .btn:active { transform: scale(0.98); }
    .btn.primary { background: var(--ink); color: var(--on-ink); }
    .btn.primary:hover { opacity: 0.85; }
    .btn.secondary { border: 1px solid var(--line-strong); color: var(--ink); }
    .btn.secondary:hover { background: var(--raised); }
    .actions { display: flex; flex-wrap: wrap; gap: 12px; }

    .section-label { display: flex; align-items: center; gap: 12px;
      color: var(--faint); margin: 0; }
    .section-label b { font-weight: 400; color: var(--accent-text); }
    .section-label::after { content: ""; flex: 1; height: 1px;
      background: var(--line); }
    .dot-title { font-family: var(--dot); font-weight: 700; font-size: 32px;
      line-height: 36px; text-transform: uppercase; margin: 24px 0 0; }

    footer.site { margin-top: 96px; border-top: 1px solid var(--line); }
    footer.site .main { display: grid; gap: 24px; padding: 48px 16px; }
    footer.site .name { font-family: var(--dot); font-weight: 700;
      font-size: 32px; line-height: 36px; margin: 0; }
    footer.site p { margin: 0; font-size: 13px; line-height: 18px; }
    footer.site .links { display: flex; flex-wrap: wrap; gap: 8px 20px; }
    footer.site .links a { text-decoration: none; color: var(--muted); }
    footer.site .links a:hover { color: var(--ink); }
    footer.site .bottom { border-top: 1px solid var(--line); }
    footer.site .bottom .wrap { display: flex; justify-content: space-between;
      flex-wrap: wrap; gap: 12px; padding-top: 20px; padding-bottom: 20px; }
    footer.site .bottom a { text-decoration: none; }
    footer.site .bottom a:hover { color: var(--ink); }
    @media (min-width: 640px) {
      footer.site .main { grid-template-columns: 1fr auto; align-items: end;
        padding: 48px 24px; }
    }
    @media (prefers-reduced-motion: reduce) {
      *, *::before, *::after { animation: none !important;
        transition: none !important; }
    }`;

// The <head> every page shares: fonts, the Dotline styles, and `extra`
// (meta tags and page styles).
function head(title, extra = '') {
  return `<meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escape(title)}</title>
  <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32.png">
  <link rel="icon" type="image/png" sizes="64x64" href="/favicon-64.png">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  <meta name="theme-color" media="(prefers-color-scheme: dark)" content="#000000">
  <meta name="theme-color" media="(prefers-color-scheme: light)" content="#f2f2f2">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Doto:wght@700;900&family=Geist:wght@400;500;600&family=Geist+Mono:wght@400;500&display=swap">
  ${extra}`;
}

// Lucide icons (https://lucide.dev, ISC license), inline so the page needs
// no extra request. They take the colour and size of their text.
const ICONS = {
  'arrow-down': '<path d="M12 5v14"/><path d="m19 12-7 7-7-7"/>',
  'arrow-up-right': '<path d="M7 7h10v10"/><path d="M7 17 17 7"/>',
};

function icon(name) {
  return `<svg class="icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS[name]}</svg>`;
}

function topBar() {
  return `<header class="top">
    <div class="wrap">
      <a class="brand" href="/" aria-label="${APP_NAME} home"><span class="status"></span>${APP_NAME}</a>
      <nav class="label" aria-label="Main">
        <a href="/privacy-policy">Privacy</a>
        <a href="${GITHUB}">GitHub ${icon('arrow-up-right')}</a>
      </nav>
    </div>
  </header>`;
}

function siteFooter() {
  return `<footer class="site">
    <div class="wrap main">
      <div>
        <p class="name">${APP_NAME}</p>
        <p class="muted" style="margin-top:12px">Free comic reader, without ads. Made by
        <a href="${KURODEV}">Kurodev</a>.</p>
      </div>
      <div class="links label">
        <a href="${DOWNLOAD}">Download</a>
        <a href="/privacy-policy">Privacy Policy</a>
        <a href="${GITHUB}">GitHub</a>
        <a href="${ISSUES}">Contact</a>
      </div>
    </div>
    <div class="bottom">
      <div class="wrap label faint">
        <span>© ${new Date().getFullYear()} Kurodev</span>
        <a href="${KURODEV}">kurodev.org ${icon('arrow-up-right')}</a>
      </div>
    </div>
  </footer>`;
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
  ${head(
    docTitle,
    `<meta name="description" content="${escape(desc)}">
  ${og}
  <meta name="twitter:card" content="${image ? 'summary_large_image' : 'summary'}">
  <style>${STYLE}
    body { min-height: 100vh; display: flex; flex-direction: column; }
    main { position: relative; flex: 1; display: grid; place-items: center;
      overflow: hidden; }
    .card { position: relative; width: 100%; max-width: 380px;
      padding: 40px 16px 48px; text-align: center; }
    .cover { width: 200px; aspect-ratio: 2 / 3; object-fit: cover;
      margin: 0 auto 24px; border-radius: 20px; border: 1px solid var(--line);
      background: var(--surface); }
    .meta { display: inline-flex; align-items: center; gap: 8px;
      color: var(--muted); }
    h1 { font-size: 26px; line-height: 32px; font-weight: 500;
      letter-spacing: -0.01em; margin: 12px 0; }
    .desc { color: var(--muted); margin: 0 0 32px; }
    .btn { display: flex; width: 100%; margin-top: 12px; }
    .missing { font-family: var(--dot); font-weight: 900; font-size: 72px;
      line-height: 1; color: var(--faint); margin: 0 0 8px; }
  </style>`,
  )}
</head>
<body>
  ${topBar()}
  <main>
    <div class="dot-grid" aria-hidden="true"></div>
    <div class="card">
      ${missing ? '<p class="missing" aria-hidden="true">404</p>' : ''}
      ${image ? `<img class="cover" src="${escape(image)}" alt="">` : ''}
      ${meta ? `<div class="meta label"><span class="status ok"></span>${escape(meta)}</div>` : ''}
      <h1>${escape(heading)}</h1>
      <p class="desc">${escape(desc)}</p>
      ${missing ? '' : `<a class="btn primary label" href="${escape(intentLink(url))}">Open in the app</a>`}
      <a class="btn secondary label" href="${DOWNLOAD}">Download the app</a>
    </div>
  </main>
</body>
</html>`;
}

export function privacyPage() {
  return `<!doctype html>
<html lang="en">
<head>
  ${head(
    `Privacy Policy — ${APP_NAME}`,
    `<meta name="description" content="What data ${APP_NAME} stores and where it is sent.">
  <style>${STYLE}
    main.wrap { padding-top: 48px; }
    html { scroll-behavior: smooth; }
    .layout { display: grid; gap: 64px; margin-top: 24px; }
    article { max-width: 680px; }
    article > p:first-child { margin-top: 0; }
    aside { display: none; }
    .toc { position: sticky; top: 104px; display: grid; gap: 0;
      padding-left: 20px; border-left: 1px solid var(--line); }
    .toc p { margin: 0 0 8px; }
    .toc a { color: var(--muted); text-decoration: none; padding: 6px 0;
      font-size: 13px; line-height: 18px; }
    .toc a:hover { color: var(--ink); }
    h2[id] { scroll-margin-top: 88px; }
    @media (min-width: 900px) {
      .layout { grid-template-columns: minmax(0, 680px) 1fr; }
      aside { display: block; }
    }
    h1 { font-family: var(--dot); font-weight: 900; font-size: 40px;
      line-height: 44px; text-transform: uppercase; margin: 24px 0 8px; }
    h2 { font-size: 17px; line-height: 24px; font-weight: 500;
      margin: 40px 0 8px; padding-top: 24px; border-top: 1px solid var(--line); }
    p, li { color: var(--muted); line-height: 24px; }
    li { margin-bottom: 8px; }
    ul { padding-left: 20px; }
    a { text-underline-offset: 3px; }
    article a { color: var(--ink); }
    code { font-family: var(--mono); font-size: 13px; color: var(--ink);
      background: var(--raised); padding: 2px 6px; border-radius: 6px; }
    @media (min-width: 640px) { h1 { font-size: 48px; line-height: 52px; } }
  </style>`,
  )}
</head>
<body>
  ${topBar()}
  <main class="wrap">
    <p class="section-label label"><b>§</b> Legal</p>
    <h1>Privacy Policy</h1>
    <p class="data faint">Last updated ${PRIVACY_UPDATED}</p>
    <div class="layout">
    <article>

    <p>${APP_NAME} is an app for reading comics on Android and desktop, made by Kurodev.
    It was called BacaKomik before. This page explains what data the app
    uses and where that data is sent.</p>

    <h2 id="data-on-your-device">Data on your device</h2>
    <p>Bookmarks, categories, reading history (the last chapter and page),
    settings, installed extensions and downloaded chapters are kept in the
    app's storage on your device. This data is not sent to our servers.</p>

    <h2 id="comic-content-and-sources">Comic content and sources</h2>
    <p>Comic lists, details and chapter pages come from the source you pick.
    The bundled source for the site bacakomik.my reads from our server
    <code>api-bacakomik.kurodev.org</code>. Other sources are extensions:
    small scripts the app installs from an extension repo (by default
    <code>yoru-ext.kurodev.org</code>, or a repo you add) and that
    connect directly to the comic site they read. These requests do not carry
    your Google account, bookmarks or reading history. Like any web server,
    our server and the comic sites can log your IP address and the time of a
    request for technical purposes. Extensions from repos you add yourself
    are not made or checked by us, so only add repos you trust.</p>
    <p>When a site asks for a bot check, the app opens it in a built-in
    WebView and keeps the cookies that site sets, so the next requests to that
    site pass. You can clear these cookies from the WebView menu.</p>

    <h2 id="google-drive-sync-optional">Google Drive sync (optional)</h2>
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

    <h2 id="backups-and-imports">Backups and imports</h2>
    <p>Backup files, Mihon / Tachiyomi backups and Comix.to exports are read
    and written on your device only. A file leaves your device only if you
    share or move it yourself.</p>

    <h2 id="app-updates">App updates</h2>
    <p>The app checks for new versions and downloads them from GitHub. These
    requests do not carry personal data.</p>

    <h2 id="ads-and-tracking">Ads and tracking</h2>
    <p>${APP_NAME} has no ads, analytics or third-party trackers.</p>

    <h2 id="contact">Contact</h2>
    <p>Questions about privacy can be sent through
    <a href="${ISSUES}">GitHub Issues</a>.</p>
    </article>
      <aside>
        <nav class="toc" aria-label="On this page">
          <p class="label faint">On this page</p>
          <a href="#data-on-your-device">Data on your device</a>
          <a href="#comic-content-and-sources">Comic content and sources</a>
          <a href="#google-drive-sync-optional">Google Drive sync</a>
          <a href="#backups-and-imports">Backups and imports</a>
          <a href="#app-updates">App updates</a>
          <a href="#ads-and-tracking">Ads and tracking</a>
          <a href="#contact">Contact</a>
        </nav>
      </aside>
    </div>
  </main>
  ${siteFooter()}
</body>
</html>`;
}

// Home page features: a title and one line each.
const FEATURES = [
  ['Several sources', 'Sources install as extensions, so new sites need no app update.'],
  ['Browse and search', 'Latest and popular comics, title search, and filters by the source’s own genres, type and status.'],
  ['A reader that remembers', 'Vertical strip or page by page, zoom and auto-scroll. Resumes at the page you stopped at.'],
  ['Bookmarks and history', 'Your own categories, new chapter badges, and a reading history that keeps the last page.'],
  ['Offline reading', 'Download chapters and read them without a connection.'],
  ['Bring your library', 'Move it to another source, or import a Mihon / Tachiyomi backup or a Comix.to export.'],
  ['Google Drive sync', 'Optional. Bookmarks and history go to a hidden app folder in your own Drive; the app cannot see your other files.'],
  ['Backup and restore', 'Save your whole library to a file and bring it back later.'],
];

const SCREENS = [
  ['home', 'Home: continue reading, new series, latest updates'],
  ['detail', 'Comic details with source, stats and synopsis'],
  ['reader', 'Reader with chapter bar and page meter'],
];

export function homePage(origin) {
  const desc =
    'An app for reading manga, manhwa and manhua from several sources, on Android, Windows, macOS and Linux.';
  const features = FEATURES.map(
    ([title, text], i) => `<li>
          <span class="data faint">${String(i + 1).padStart(2, '0')}</span>
          <div><h3>${escape(title)}</h3><p>${escape(text)}</p></div>
        </li>`,
  ).join('\n        ');
  const screens = SCREENS.map(
    ([name, alt]) =>
      `<img src="${SCREENSHOT(name)}" alt="${escape(alt)}" width="540" height="1200" loading="lazy">`,
  ).join('\n        ');

  return `<!doctype html>
<html lang="en">
<head>
  ${head(
    `${APP_NAME} — Read comics on Android and desktop`,
    `<meta name="description" content="${escape(desc)}">
  <meta property="og:site_name" content="${APP_NAME}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="${escape(`${origin}/`)}">
  <meta property="og:title" content="${APP_NAME}">
  <meta property="og:description" content="${escape(desc)}">
  <style>${STYLE}
    .hero { position: relative; overflow: hidden;
      border-bottom: 1px solid var(--line); }
    .hero .wrap { position: relative; display: grid; gap: 48px;
      padding-top: 64px; padding-bottom: 56px; }
    .hero .kicker { display: flex; align-items: center; gap: 8px;
      color: var(--muted); margin: 0; }
    h1 { font-family: var(--dot); font-weight: 900;
      font-size: clamp(72px, 16vw, 136px); line-height: 1;
      letter-spacing: -0.02em; margin: 24px 0 0; }
    .lead { font-size: 20px; line-height: 28px; letter-spacing: -0.01em;
      color: var(--muted); max-width: 30ch; margin: 24px 0 32px; }
    .lead span { color: var(--ink); }
    .platforms { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 24px; }
    .chip { display: inline-flex; align-items: center; height: 28px;
      padding: 0 12px; border-radius: 999px; color: var(--muted);
      border: 1px solid var(--line-strong); }
    .screens { display: flex; gap: 12px; overflow-x: auto;
      scroll-snap-type: x mandatory; margin: 0 -16px; padding: 0 16px; }
    .screens img { width: 180px; height: auto; flex: none;
      scroll-snap-align: start; border-radius: 20px;
      border: 1px solid var(--line); background: var(--surface); }
    @media (min-width: 900px) {
      .hero .wrap { grid-template-columns: 1fr auto; align-items: center;
        padding-top: 96px; padding-bottom: 80px; }
      .screens { margin: 0; padding: 0; overflow: visible; }
      .screens img { width: 170px; }
      .screens img:nth-child(2) { transform: translateY(-24px); }
    }
    section.block { padding-top: 64px; }
    .features { list-style: none; margin: 32px 0 0; padding: 0;
      display: grid; gap: 1px; background: var(--line);
      border: 1px solid var(--line); border-radius: 20px; overflow: hidden; }
    .features li { display: flex; gap: 16px; padding: 20px;
      background: var(--surface); }
    .features li > span { padding-top: 3px; }
    .features h3 { font-size: 17px; line-height: 24px; font-weight: 500;
      margin: 0 0 4px; }
    .features p { margin: 0; font-size: 13px; line-height: 20px;
      color: var(--muted); }
    @media (min-width: 640px) {
      .features { grid-template-columns: 1fr 1fr; }
    }
    .privacy { display: grid; gap: 24px; margin-top: 32px; padding: 24px;
      border: 1px dashed var(--line-strong); border-radius: 20px; }
    .privacy p { margin: 0; color: var(--muted); max-width: 60ch; }
    .privacy a { color: var(--ink); text-underline-offset: 3px; }
  </style>`,
  )}
</head>
<body>
  ${topBar()}
  <main>
    <section class="hero">
      <div class="dot-grid" aria-hidden="true"></div>
      <div class="wrap">
        <div>
          <p class="kicker label"><span class="status pulse"></span>Free · No ads · No trackers</p>
          <h1>${APP_NAME}</h1>
          <p class="lead">Read manga, manhwa and manhua from several sources.
          <span>Made by Kurodev.</span></p>
          <div class="actions">
            <a class="btn primary label" href="${DOWNLOAD}">Download the app ${icon('arrow-down')}</a>
            <a class="btn secondary label" href="${GITHUB}">GitHub ${icon('arrow-up-right')}</a>
          </div>
          <div class="platforms label" aria-label="Platforms">
            <span class="chip">Android</span><span class="chip">Windows</span>
            <span class="chip">macOS</span><span class="chip">Linux</span>
          </div>
        </div>
        <div class="screens">
        ${screens}
        </div>
      </div>
    </section>

    <section class="block wrap" id="features">
      <p class="section-label label"><b>01</b> Index</p>
      <h2 class="dot-title">Features</h2>
      <ul class="features">
        ${features}
      </ul>
    </section>

    <section class="block wrap" id="privacy">
      <p class="section-label label"><b>02</b> Data</p>
      <h2 class="dot-title">Privacy</h2>
      <div class="privacy">
        <p>Bookmarks, history and downloads stay on your device. When sync is
        on, data is only sent between your device and Google Drive. Read more in
        the <a href="/privacy-policy">Privacy Policy</a>.</p>
      </div>
    </section>
  </main>
  ${siteFooter()}
</body>
</html>`;
}
