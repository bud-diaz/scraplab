import type { CapacitorConfig } from '@capacitor/cli';

// Local dev: CAP_ENV=dev CAP_DEV_SERVER_URL=http://<lan-ip>:3000 npx cap sync ios
// (defaults to http://localhost:3000, which works from the iOS Simulator but
// not from a physical device — see the iOS build docs for the device setup).
// Production (default): points at the live ScrapLab web deployment.
const isDev = process.env.CAP_ENV === 'dev';

// The live ScrapLab deployment the native shell loads on every launch.
// Override per-build with CAP_PRODUCTION_URL=... npx cap sync ios.
//
// TODO: switch the default to https://scraplab.app once that domain is pointed
// at this deployment (and drop the vercel.app entries from allowNavigation
// below). Never ship a build with this pointing at localhost/ngrok/a preview
// deployment.
const PRODUCTION_URL = process.env.CAP_PRODUCTION_URL ?? 'https://scraplab-inky.vercel.app';

const config: CapacitorConfig = {
  appId: 'com.scraplab.app',
  appName: 'ScrapLab',
  // Capacitor requires webDir to exist even in remote-URL mode. This local
  // page is only ever seen briefly at cold launch (before the WKWebView
  // navigates to server.url) and as the offline/error fallback.
  webDir: 'capacitor-shell/www',
  server: {
    url: isDev ? (process.env.CAP_DEV_SERVER_URL ?? 'http://localhost:3000') : PRODUCTION_URL,
    cleartext: isDev,
    // Loaded when a navigation to server.url fails (offline, DNS failure, cold
    // start timeout, 5xx). Resolved against the local capacitor://localhost
    // origin, i.e. served out of the bundled webDir above — not off the remote
    // server, which by definition isn't answering at that point.
    errorPath: 'index.html',
    allowNavigation: [
      'scraplab.app',
      '*.scraplab.app',
      'scraplab-inky.vercel.app',
      '*.vercel.app',
      '*.supabase.co',
      'checkout.stripe.com',
      'billing.stripe.com',
      'js.stripe.com',
    ],
  },
  ios: {
    contentInset: 'automatic',
    // Lets server code detect "running inside the native shell" via the
    // request User-Agent header, if ever needed (e.g. to hide a "Get the
    // app" banner already inside the app).
    appendUserAgent: 'ScrapLabIOSApp',
  },
  plugins: {
    SplashScreen: {
      // src/components/native/NativeBootstrap.tsx hides this as soon as the
      // remote page hydrates, which is the normal path. launchShowDuration is
      // only a ceiling: the plugin disables touch on the whole view while the
      // splash is up, so leaving autoHide off would turn any failure to reach
      // server.url into a permanently frozen launch screen.
      launchAutoHide: true,
      launchShowDuration: 3000,
      launchFadeOutDuration: 200,
      backgroundColor: '#F8F3EA',
    },
  },
};

export default config;
