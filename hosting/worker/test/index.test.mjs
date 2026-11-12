import assert from 'node:assert/strict';
import { afterEach, test } from 'node:test';
import worker from '../src/index.js';

const ctx = { waitUntil() {} };
const realFetch = globalThis.fetch;
afterEach(() => {
  globalThis.fetch = realFetch;
});

const get = (path) =>
  worker.fetch(new Request(`https://yoru.kurodev.org${path}`), {}, ctx);

function mockApi(status, data) {
  globalThis.fetch = async (url) => {
    assert.equal(
      String(url),
      'https://api-bacakomik.kurodev.org/series/magic-emperor',
    );
    return new Response(JSON.stringify({ data }), { status });
  };
}

test('assetlinks.json names the app and its signing key', async () => {
  const res = await get('/.well-known/assetlinks.json');
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('Content-Type'), 'application/json');
  const entries = await res.json();
  assert.deepEqual(
    entries.map((e) => e.target.package_name),
    ['org.kurodev.yoru', 'org.kurodev.bacakomik'],
  );
  for (const entry of entries) {
    assert.equal(entry.target.sha256_cert_fingerprints.length, 1);
  }
});

test('series page carries the Open Graph preview', async () => {
  mockApi(200, {
    title: 'Magic <Emperor>',
    synopsis: 'Zhuo Yifan is a magic emperor.',
    cover: 'https://api-bacakomik.kurodev.org/img/x',
    format: 'manhua',
    status: 'ongoing',
    releaseDate: '2018',
  });
  const res = await get('/series/magic-emperor?ref=wa');
  const body = await res.text();

  assert.equal(res.status, 200);
  assert.match(
    body,
    /<meta property="og:title" content="Magic &lt;Emperor&gt; — Yoru">/,
  );
  assert.match(
    body,
    /<meta property="og:image" content="https:\/\/api-bacakomik\.kurodev\.org\/img\/x">/,
  );
  assert.match(
    body,
    /og:url" content="https:\/\/yoru\.kurodev\.org\/series\/magic-emperor"/,
  );
  assert.match(
    body,
    /intent:\/\/yoru\.kurodev\.org\/series\/magic-emperor#Intent;scheme=https;package=org\.kurodev\.yoru;/,
  );
  assert.match(body, /manhua · ongoing · 2018/);
});

test('unknown series is a 404 without an open-in-app button', async () => {
  mockApi(404, null);
  const res = await get('/series/magic-emperor');
  assert.equal(res.status, 404);
  assert.doesNotMatch(await res.text(), /Open in the app/);
});

test('API failure still serves a page that opens the app', async () => {
  globalThis.fetch = async () => {
    throw new Error('down');
  };
  const res = await get('/series/magic-emperor');
  const body = await res.text();
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('Cache-Control'), 'no-store');
  assert.match(body, /<h1>Magic Emperor<\/h1>/);
  assert.match(body, /Open in the app/);
});

test('privacy policy names the Drive scope', async () => {
  for (const path of ['/privacy-policy', '/privacy-policy/', '/privacy']) {
    const res = await get(path);
    assert.equal(res.status, 200);
    assert.equal(res.headers.get('Content-Type'), 'text/html; charset=utf-8');
    const body = await res.text();
    assert.match(body, /<h1>Privacy Policy<\/h1>/);
    assert.match(body, /drive\.appdata/);
    assert.match(body, /Limited Use/);
  }
});

test('home page describes the app and links the privacy policy', async () => {
  const res = await get('/');
  const body = await res.text();
  assert.equal(res.status, 200);
  assert.match(body, /<h1>Yoru<\/h1>/);
  assert.match(body, /href="\/privacy-policy"/);
  assert.match(body, /Google\s+Drive/);
  assert.match(body, /<link rel="icon" type="image\/png" sizes="32x32" href="\/favicon-32.png">/);
});

test('favicons are the app icon as PNG', async () => {
  for (const path of ['/favicon.ico', '/favicon-32.png', '/favicon-64.png', '/apple-touch-icon.png']) {
    const res = await get(path);
    assert.equal(res.status, 200, path);
    assert.equal(res.headers.get('Content-Type'), 'image/png', path);
    const bytes = new Uint8Array(await res.arrayBuffer());
    // PNG signature.
    assert.deepEqual([...bytes.slice(0, 4)], [0x89, 0x50, 0x4e, 0x47], path);
  }
});

test('other paths', async () => {
  assert.equal((await get('/')).status, 200);
  assert.equal((await get('/series/a/b')).status, 404);
  assert.equal((await get('/series/%3Cx%3E')).status, 404);
  assert.equal((await get('/random')).status, 404);
  const post = await worker.fetch(
    new Request('https://yoru.kurodev.org/', { method: 'POST' }),
    {},
    ctx,
  );
  assert.equal(post.status, 405);
});

test('comics from other sources get a page without an API call', async () => {
  globalThis.fetch = async () => assert.fail('no API call expected');
  for (const path of [
    '/series/voratoon:solo-leveling',
    '/series/voratoon%3Asolo-leveling',
  ]) {
    const res = await get(path);
    assert.equal(res.status, 200);
    const body = await res.text();
    assert.match(body, /Solo Leveling/);
    assert.match(body, /VoraToon/);
    assert.match(body, /series\/voratoon:solo-leveling/);
  }
});

test('altstore.json lists the iOS IPA of each release, newest first', async () => {
  globalThis.fetch = async (url, init) => {
    assert.match(String(url), /api\.github\.com\/repos\/sofyan-rs\/yoru-comic-app\/releases/);
    assert.ok(init.headers['User-Agent']);
    return new Response(
      JSON.stringify([
        {
          tag_name: 'v2.22.0',
          published_at: '2026-11-20T10:00:00Z',
          body: 'Fixes.\n\n## Which APK?\n\n| File | For |',
          assets: [
            { name: 'Yoru-2.22.0-universal.apk', browser_download_url: 'https://x/apk', size: 9 },
            { name: 'Yoru-2.22.0-ios.ipa', browser_download_url: 'https://x/ipa', size: 15725511 },
          ],
        },
        { tag_name: 'v2.21.3-beta', prerelease: true, assets: [{ name: 'Yoru-2.21.3-ios.ipa' }] },
        { tag_name: 'v2.21.2', published_at: '2026-11-01T10:00:00Z', body: '', assets: [] },
      ]),
      { status: 200 },
    );
  };
  const res = await get('/altstore.json');
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('Content-Type'), 'application/json');
  const source = await res.json();
  assert.equal(source.sourceURL, 'https://yoru.kurodev.org/altstore.json');
  const [app] = source.apps;
  assert.equal(app.bundleIdentifier, 'org.kurodev.yoru');
  assert.deepEqual(app.versions, [
    {
      version: '2.22.0',
      date: '2026-11-20T10:00:00Z',
      localizedDescription: 'Fixes.',
      downloadURL: 'https://x/ipa',
      size: 15725511,
      minOSVersion: '15.0',
    },
  ]);
});

test('altstore.json is not cached when GitHub fails', async () => {
  globalThis.fetch = async () => new Response('rate limited', { status: 403 });
  const res = await get('/altstore.json');
  assert.equal(res.status, 502);
  assert.equal(res.headers.get('Cache-Control'), 'no-store');
});
