import assert from 'node:assert/strict';
import { afterEach, test } from 'node:test';
import worker from '../src/index.js';

const ctx = { waitUntil() {} };
const realFetch = globalThis.fetch;
afterEach(() => {
  globalThis.fetch = realFetch;
});

const get = (path) =>
  worker.fetch(new Request(`https://bacakomik.kurodev.org${path}`), {}, ctx);

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
  const [entry] = await res.json();
  assert.equal(entry.target.package_name, 'org.kurodev.bacakomik');
  assert.equal(entry.target.sha256_cert_fingerprints.length, 1);
});

test('series page carries the Open Graph preview', async () => {
  mockApi(200, {
    title: 'Magic <Emperor>',
    synopsis: 'Zhuo Yifan adalah seorang kaisar sihir.',
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
    /<meta property="og:title" content="Magic &lt;Emperor&gt; — BacaKomik">/,
  );
  assert.match(
    body,
    /<meta property="og:image" content="https:\/\/api-bacakomik\.kurodev\.org\/img\/x">/,
  );
  assert.match(
    body,
    /og:url" content="https:\/\/bacakomik\.kurodev\.org\/series\/magic-emperor"/,
  );
  assert.match(
    body,
    /intent:\/\/bacakomik\.kurodev\.org\/series\/magic-emperor#Intent;scheme=https;package=org\.kurodev\.bacakomik;/,
  );
  assert.match(body, /manhua · ongoing · 2018/);
});

test('unknown series is a 404 without an open-in-app button', async () => {
  mockApi(404, null);
  const res = await get('/series/magic-emperor');
  assert.equal(res.status, 404);
  assert.doesNotMatch(await res.text(), /Buka di aplikasi/);
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
  assert.match(body, /Buka di aplikasi/);
});

test('privacy policy names the Drive scope', async () => {
  for (const path of ['/privacy-policy', '/privacy-policy/', '/privacy']) {
    const res = await get(path);
    assert.equal(res.status, 200);
    assert.equal(res.headers.get('Content-Type'), 'text/html; charset=utf-8');
    const body = await res.text();
    assert.match(body, /<h1>Kebijakan Privasi<\/h1>/);
    assert.match(body, /drive\.appdata/);
    assert.match(body, /Limited Use/);
  }
});

test('other paths', async () => {
  assert.equal((await get('/')).status, 200);
  assert.equal((await get('/series/a/b')).status, 404);
  assert.equal((await get('/series/%3Cx%3E')).status, 404);
  assert.equal((await get('/random')).status, 404);
  const post = await worker.fetch(
    new Request('https://bacakomik.kurodev.org/', { method: 'POST' }),
    {},
    ctx,
  );
  assert.equal(post.status, 405);
});
