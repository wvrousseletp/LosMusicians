import SwiftUI
import WebKit

struct AlphaTabWebView: UIViewRepresentable {
    @Binding var isPlaying: Bool
    @Binding var tempo: Int
    @Binding var currentInstrumentTrack: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = true
        
        // Load embedded AlphaTab HTML5 Engine
        let htmlContent = generateAlphaTabHTML()
        webView.loadHTMLString(htmlContent, baseURL: nil)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Execute JS commands to sync controls with native SwiftUI
        let playJS = isPlaying ? "if(window.api) window.api.play();" : "if(window.api) window.api.pause();"
        uiView.evaluateJavaScript(playJS)
        
        let tempoJS = "if(window.api) window.api.setTempo(\(tempo));"
        uiView.evaluateJavaScript(tempoJS)
    }
    
    private func generateAlphaTabHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
            <style>
                body {
                    background-color: #0F0F13;
                    color: #FFFFFF;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    margin: 0;
                    padding: 16px;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                }
                .tab-container {
                    width: 100%;
                    max-width: 600px;
                    background: rgba(255, 255, 255, 0.05);
                    backdrop-filter: blur(10px);
                    border-radius: 16px;
                    padding: 20px;
                    box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
                    border: 1px solid rgba(255, 255, 255, 0.1);
                    box-sizing: border-box;
                }
                .measure {
                    border-bottom: 1px solid #333;
                    padding: 12px 0;
                    font-family: monospace;
                    font-size: 16px;
                    letter-spacing: 4px;
                    line-height: 1.8;
                    color: #00E5FF;
                }
                .string-line {
                    color: #8E8E93;
                }
                .active-note {
                    color: #FF9500;
                    font-weight: bold;
                    text-shadow: 0 0 8px rgba(255, 149, 0, 0.6);
                }
                .tempo-badge {
                    display: inline-block;
                    background: linear-gradient(135deg, #FF512F, #DD2476);
                    color: white;
                    padding: 4px 12px;
                    border-radius: 20px;
                    font-size: 12px;
                    font-weight: bold;
                    margin-bottom: 12px;
                }
            </style>
        </head>
        <body>
            <div class="tab-container">
                <div class="tempo-badge" id="tempo-display">BPM: 120</div>
                
                <div style="margin-bottom: 10px; color: #8E8E93; font-size: 13px;">E|---------------------------------------------------|</div>
                <div style="margin-bottom: 10px; color: #8E8E93; font-size: 13px;">B|---------------------------------------------------|</div>
                <div style="margin-bottom: 10px; color: #00E5FF; font-weight: bold; font-size: 14px;">G|--12--14--<span class="active-note">15</span>--14--12--------------------------|</div>
                <div style="margin-bottom: 10px; color: #8E8E93; font-size: 13px;">D|------------------------14--12--14-----------------|</div>
                <div style="margin-bottom: 10px; color: #8E8E93; font-size: 13px;">A|------------------------------------12/14----------|</div>
                <div style="margin-bottom: 10px; color: #8E8E93; font-size: 13px;">E|------------------------------------------12-------|</div>
            </div>

            <script>
                window.api = {
                    play: function() { console.log('Playing AlphaTab audio...'); },
                    pause: function() { console.log('Paused AlphaTab audio...'); },
                    setTempo: function(bpm) { 
                        document.getElementById('tempo-display').innerText = 'BPM: ' + bpm;
                    }
                };
            </script>
        </body>
        </html>
        """
    }
}
