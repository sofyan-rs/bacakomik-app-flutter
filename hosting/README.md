# Link hosting

`worker/` is a Cloudflare Worker for `bacakomik.kurodev.org`, the host of
shared series links (`https://bacakomik.kurodev.org/series/<slug>`).

- `/.well-known/assetlinks.json` lets Android verify the App Link, so the
  link opens BacaKomik directly instead of the browser. It lists the
  SHA-256 fingerprint of the release (upload) signing key in
  `src/index.js`. Update it if the key changes:
  `keytool -list -v -keystore <keystore.jks> -alias upload`.
- `/series/<slug>` is the fallback page, shown when the app is not
  installed or the link is opened in a browser. It fetches the series from
  the API for the Open Graph preview (title, cover, synopsis) that chat
  apps show, and offers "Open in the app" and "Download APK". Pages are
  cached at the edge for an hour.
- `/` is the app's home page: what the app does, the APK download and a
  privacy link. It is the homepage URL of the Google OAuth consent screen.
- `/privacy-policy` is the privacy policy (`/privacy` works too). It is the
  privacy policy URL of the Google OAuth consent screen used by Drive
  sync; update `privacyPage()` and `PRIVACY_UPDATED` when the app starts
  collecting or sending other data.

## Deploy

```sh
cd hosting/worker
npm install
npm test            # node --test, no Cloudflare needed
npx wrangler login  # once
npm run deploy
```

`kurodev.org` must be a zone on the same Cloudflare account; deploy
creates the `bacakomik` DNS record (custom domain in `wrangler.toml`).

Android verifies the link when the app is installed. After the first
deploy, re-verify an installed app:

```sh
adb shell pm verify-app-links --re-verify org.kurodev.bacakomik
adb shell pm get-app-links org.kurodev.bacakomik   # bacakomik.kurodev.org: verified
```
