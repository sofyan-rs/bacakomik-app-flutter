// Cloudflare Worker for bacakomik.kurodev.org, the host of shared links
// (https://bacakomik.kurodev.org/series/<slug>).
//
// - /.well-known/assetlinks.json lets Android verify the App Link, so the
//   link opens BacaKomik directly when it is installed.
// - /series/<slug> is the fallback page when it is not (or when the link
//   is opened in a browser). It carries Open Graph tags with the series
//   title, cover and synopsis so chat apps show a preview.
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
const PRIVACY_UPDATED = '21 Oktober 2026';

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

    if (/^\/privacy(-policy)?\/?$/.test(url.pathname)) {
      return html(privacyPage());
    }
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

export function privacyPage() {
  return `<!doctype html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Kebijakan Privasi — ${APP_NAME}</title>
  <meta name="description" content="Data apa yang disimpan ${APP_NAME} dan ke mana data itu dikirim.">
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
    <h1>Kebijakan Privasi</h1>
    <p class="updated">Terakhir diperbarui ${PRIVACY_UPDATED}</p>

    <p>${APP_NAME} adalah aplikasi Android untuk membaca komik, dibuat oleh
    Kurodev. Halaman ini menjelaskan data apa yang dipakai aplikasi dan ke
    mana data itu dikirim.</p>

    <h2>Data di perangkat</h2>
    <p>Bookmark, riwayat baca (chapter dan halaman terakhir), pengaturan, dan
    chapter yang diunduh disimpan di penyimpanan aplikasi di perangkat kamu.
    Data ini tidak dikirim ke server kami.</p>

    <h2>Konten komik</h2>
    <p>Daftar komik, detail, dan halaman chapter diambil dari server
    <code>api-bacakomik.kurodev.org</code>. Permintaan ini tidak membawa
    akun, bookmark, atau riwayat baca kamu. Seperti server web pada umumnya,
    server dapat mencatat alamat IP dan waktu permintaan untuk keperluan
    teknis.</p>

    <h2>Sinkron Google Drive (opsional)</h2>
    <p>Jika kamu menyalakan sinkron, aplikasi meminta login Google dengan
    akses <code>drive.appdata</code>. Akses ini hanya membuka folder data
    aplikasi yang tersembunyi di Google Drive kamu, bukan file Drive
    lainnya.</p>
    <ul>
      <li>Yang disimpan di folder itu: bookmark, riwayat baca, dan catatan
      item yang kamu hapus, dalam satu file.</li>
      <li>Alamat email akun Google dipakai untuk menampilkan akun yang
      tersambung di aplikasi.</li>
      <li>Data dikirim langsung antara perangkat kamu dan Google. Kami tidak
      menerima, menyimpan, atau membagikan data tersebut.</li>
      <li>Kamu bisa memutus sinkron kapan saja di menu Lainnya, dan mencabut
      akses aplikasi di
      <a href="https://myaccount.google.com/permissions">pengaturan akun
      Google</a>. Data di Drive dapat dihapus dari Google Drive → Setelan →
      Kelola aplikasi.</li>
    </ul>
    <p>Penggunaan data dari Google API mengikuti
    <a href="https://developers.google.com/terms/api-services-user-data-policy">Google
    API Services User Data Policy</a>, termasuk ketentuan Limited Use.</p>

    <h2>Pembaruan aplikasi</h2>
    <p>Aplikasi memeriksa versi terbaru melalui GitHub. Permintaan ini tidak
    membawa data pribadi.</p>

    <h2>Iklan dan pelacakan</h2>
    <p>${APP_NAME} tidak memuat iklan, analitik, atau pelacak pihak
    ketiga.</p>

    <h2>Kontak</h2>
    <p>Pertanyaan tentang privasi bisa dikirim lewat
    <a href="${ISSUES}">GitHub Issues</a>.</p>
  </main>
</body>
</html>`;
}
