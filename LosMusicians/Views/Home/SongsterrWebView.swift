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
        
        // Inject JS to hide Songsterr's header and footer so it feels native
        let hideHeaderFooterScript = """
            var css = 'header, footer, nav, [class*="Header"], [class*="Footer"], [class*="Nav"], [class*="Ad"], #bottom-ad, #top-ad { display: none !important; }';
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
        if let url = URL(string: "https://www.songsterr.com/a/wsa/song/\(songId)") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
