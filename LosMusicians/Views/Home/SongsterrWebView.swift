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
            let js = """
            var playBtn = document.querySelector('#control-play, [data-testid="control-play"], button[title*="Play"], button[aria-label*="Play"]');
            if (playBtn) { 
                playBtn.click(); 
            } else { 
                var e = new KeyboardEvent('keydown', { key: ' ', code: 'Space', keyCode: 32, which: 32, bubbles: true });
                document.dispatchEvent(e);
                window.dispatchEvent(e);
            }
            """
            webView?.evaluateJavaScript(js, completionHandler: nil)
        }
        
        @objc func handleSetSpeed(_ notification: Notification) {
            guard let speed = notification.userInfo?["speed"] as? Double else { return }
            let js = """
            var medias = document.querySelectorAll('audio, video');
            medias.forEach(m => m.playbackRate = \(speed));
            """
            webView?.evaluateJavaScript(js, completionHandler: nil)
        }
        
        @objc func handleToggleLoop() {
            let js = """
            var loopBtn = document.querySelector('#control-loop, [data-testid="control-loop"], button[title*="Loop"], button[aria-label*="Loop"]');
            if (loopBtn) { 
                loopBtn.click(); 
            } else { 
                var e = new KeyboardEvent('keydown', { key: 'l', code: 'KeyL', keyCode: 76, which: 76, bubbles: true });
                document.dispatchEvent(e);
                window.dispatchEvent(e);
            }
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
        // CRITICAL: Allow programmatic audio playback triggered by Swift buttons (outside WebView)
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
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
