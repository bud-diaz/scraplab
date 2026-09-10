import type { CapacitorConfig } from '@capacitor/cli';

// Local dev: CAP_ENV=dev CAP_DEV_SERVER_URL=http://<lan-ip>:3000 npx cap sync ios
// (defaults to http://localhost:3000, which works from the iOS Simulator but
// not from a physical device — see the iOS build docs for the device setup).
// Production (default): points at the live ScrapLab web deployment.
const isDev = process.env.CAP_ENV === 'dev';

// TODO: replace with the real production domain before any TestFlight/App
// Store build. Never ship a build with this pointing at localhost/ngrok/a
// preview deployment.
const PRODUCTION_URL = 'https://scraplab.app';

const config: CapacitorConfig = {
  appId: 'com.scraplab.app',
  appName: 'ScrapLab',
  // Capacitor requires webDir to exist even in remote-URL mode. This local
  // page is only ever seen briefly at cold launch (before the WKWebView
  // navigates to server.url) and as the native offline/error fallback.
  webDir: 'capacitor-shell/www',
  server: {
    url: isDev ? (process.env.CAP_DEV_SERVER_URL ?? 'http://localhost:3000') : PRODUCTION_URL,
    cleartext: isDev,
    allowNavigation: [
      'scraplab.app',
      '*.scraplab.app',
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
      // Hidden manually once the remote page has hydrated — see
      // src/components/native/NativeBootstrap.tsx.
      launchAutoHide: false,
      backgroundColor: '#F8F3EA',
    },
  },
};

export default config;
