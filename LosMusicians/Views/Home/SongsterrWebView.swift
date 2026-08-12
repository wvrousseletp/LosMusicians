import SwiftUI
import WebKit

struct SongsterrWebView: UIViewRepresentable {
    let songId: Int
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        configuration.allowsInlineMediaPlayback = true
        
        // Inject JS to hide Songsterr's header, footer, and ads so only the tab and bottom controls show
        let hideHeaderFooterScript = """
            var css = 'header, nav, aside, [class*="Header"], [class*="Nav"], [class*="Ad"], #bottom-ad, #top-ad, a[href*="apps.apple.com"], a[href*="play.google.com"], [class*="Banner"], [class*="promo"], [id*="banner"], [id*="promo"] { display: none !important; }';
            var style = document.createElement('style');
            style.type = 'text/css';
            style.appendChild(document.createTextNode(css));
            document.head.appendChild(style);
        """
        let userScript = WKUserScript(source: hideHeaderFooterScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        configuration.userContentController.addUserScript(userScript)
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        webView.backgroundColor = .black
        webView.isOpaque = false
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: "https://www.songsterr.com/a/wa/song?id=\(songId)") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
