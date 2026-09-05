import Capacitor
import WebKit

/// Subclasses Capacitor's bridge view controller purely to add an offline /
/// load-failure fallback. `server.url` (see capacitor.config.ts) points the
/// WKWebView at the live production deployment on every launch — with no
/// local bundle behind it, a dropped connection, a cold Vercel start, or a
/// 5xx would otherwise leave the user staring at a blank webview or Safari's
/// native error page, which reads badly in App Review and in general use.
///
/// NOTE: written without a macOS/Xcode toolchain available to compile it —
/// verify this builds and behaves as expected the first time it's opened in
/// Xcode, in particular that `ScrapLabViewController` is reachable as the
/// storyboard's custom class (module "App") and that the retry scheme below
/// doesn't collide with anything else registered on the WKWebView.
class ScrapLabViewController: CAPBridgeViewController {

    // Keep in sync with PRODUCTION_URL in capacitor.config.ts.
    private static let productionURL = URL(string: "https://scraplab.app")!

    override func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showOfflineFallback()
    }

    override func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showOfflineFallback()
    }

    override func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // The local fallback page's "Retry" button navigates to this
        // sentinel URL instead of doing a plain reload (which would just
        // reload the local fallback page itself, not the real app).
        if navigationAction.request.url?.scheme == "scraplab-retry" {
            decisionHandler(.cancel)
            webView.load(URLRequest(url: Self.productionURL))
            return
        }
        super.webView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
    }

    private func showOfflineFallback() {
        guard let webView = self.webView,
              let fallbackURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "public")
        else { return }
        webView.loadFileURL(fallbackURL, allowingReadAccessTo: fallbackURL.deletingLastPathComponent())
    }
}
