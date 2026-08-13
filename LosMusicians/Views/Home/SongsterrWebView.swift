import SwiftUI
import WebKit

struct SongsterrWebView: UIViewRepresentable {
    let songId: Int
    
    class Coordinator: NSObject {
        var webView: WKWebView?
        
        override init() {
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(handlePlayPause), name: NSNotification.Name("SongsterrPlayPause"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleSetSpeed(_:)), name: NSNotification.Name("SongsterrSetSpeed"), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleToggleLoop), name: NSNotification.Name("SongsterrToggleLoop"), object: nil)
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc func handlePlayPause() {
            // Songsterr uses the Spacebar to toggle Play/Pause
            let js = "document.dispatchEvent(new KeyboardEvent('keydown', { key: ' ', code: 'Space', keyCode: 32, which: 32, bubbles: true }));"
            webView?.evaluateJavaScript(js, completionHandler: nil)
        }
        
        @objc func handleSetSpeed(_ notification: Notification) {
            guard let speed = notification.userInfo?["speed"] as? Double else { return }
            // Songsterr doesn't have a simple keyboard shortcut for speed, but we can try to click the speed button if we can find it.
            // Actually, we can just dispatch the spacebar for now, or find the audio element if possible.
            // Finding the specific React component is hard, but we can try setting window.playbackRate if they expose it.
            // As a fallback, we just send a console log.
            let js = "console.log('Speed change requested to \(speed)');"
            webView?.evaluateJavaScript(js, completionHandler: nil)
        }
        
        @objc func handleToggleLoop() {
            // Attempt to click the loop button or dispatch 'l'
            let js = """
            var loopBtn = document.querySelector('button[title*="Loop"], button[aria-label*="Loop"]');
            if (loopBtn) { loopBtn.click(); }
            else { document.dispatchEvent(new KeyboardEvent('keydown', { key: 'l', code: 'KeyL', keyCode: 76, which: 76, bubbles: true })); }
            """
            webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        configuration.allowsInlineMediaPlayback = true
        
        // Hide Songsterr's UI elements: header, footer, ads, AND bottom player controls (we provide our own)
        let hideHeaderFooterScript = """
            var css = 'header, nav, aside, [class*="Header"], [class*="Nav"], [class*="Ad"], #bottom-ad, #top-ad, a[href*="apps.apple.com"], a[href*="play.google.com"], [class*="Banner"], [class*="promo"], [id*="banner"], [id*="promo"], [class*="Controls"], [class*="PlayerControls"], [class*="BottomBar"], section[class*="Bottom"] { display: none !important; }';
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
        
        context.coordinator.webView = webView
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url == nil {
            if let url = URL(string: "https://www.songsterr.com/a/wa/song?id=\(songId)") {
                let request = URLRequest(url: url)
                webView.load(request)
            }
        }
    }
}
