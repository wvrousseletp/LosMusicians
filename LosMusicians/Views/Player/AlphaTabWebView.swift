import SwiftUI
import WebKit

struct AlphaTabWebView: UIViewRepresentable {
    var alphaTex: String? = nil
    @Binding var isPlaying: Bool
    @Binding var tempo: Int
    @Binding var currentInstrumentTrack: String
    
    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: AlphaTabWebView
        
        init(_ parent: AlphaTabWebView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "alphaTabBridge", let dict = message.body as? [String: Any] {
                if let type = dict["type"] as? String, type == "playedNote", let midi = dict["midi"] as? Int {
                    NotificationCenter.default.post(name: NSNotification.Name("AlphaTabPlayedNote"), object: nil, userInfo: ["midi": midi])
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        
        config.userContentController.add(context.coordinator, name: "alphaTabBridge")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = true
        
        // Load embedded AlphaTab HTML5 Engine
        let htmlContent = generateAlphaTabHTML(with: alphaTex)
        webView.loadHTMLString(htmlContent, baseURL: URL(string: "https://www.alphatab.net/"))
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Execute JS commands to sync controls with native SwiftUI
        let playJS = isPlaying ? "if(window.api) window.api.play();" : "if(window.api) window.api.pause();"
        uiView.evaluateJavaScript(playJS)
        
        let tempoJS = "if(window.api) window.api.setTempo(\(tempo));"
        uiView.evaluateJavaScript(tempoJS)
    }
    
    private func generateAlphaTabHTML(with tex: String?) -> String {
        let texString = tex ?? ""
        // Escaping the alphaTex string for Javascript
        let escapedTex = texString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
            <script src="https://cdn.jsdelivr.net/npm/@coderline/alphatab@latest/dist/alphaTab.js"></script>
            <style>
                body {
                    background-color: #0F0F13;
                    color: #FFFFFF;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    margin: 0;
                    padding: 16px;
                }
                #alphaTab {
                    width: 100%;
                    background: rgba(255, 255, 255, 0.05);
                    border-radius: 16px;
                    padding: 10px;
                }
            </style>
        </head>
        <body>
            <div id="alphaTab" data-tex="true"></div>

            <script>
                var wrapper = document.getElementById('alphaTab');
                var texData = "\(escapedTex)";
                
                // Tratar fallback para tex vazio
                if (texData.trim() === "") {
                    texData = "\\\\title \\"Exemplo\\" \\n . \\n :4 5.6.7.8 | 8.7.6.5";
                }

                var api = new alphaTab.AlphaTabApi(wrapper, {
                    core: {
                        engine: 'svg'
                    },
                    display: {
                        layoutMode: 'page',
                        staveProfile: 'Default'
                    },
                    player: {
                        enablePlayer: true,
                        enableUserInteraction: false,
                        soundFont: 'https://cdn.jsdelivr.net/npm/@coderline/alphatab@latest/dist/soundfont/sonivox.sf2'
                    }
                });
                
                api.tex(texData);

                api.playedBeat.on(function (beat) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.alphaTabBridge) {
                        for (var i = 0; i < beat.notes.length; i++) {
                            window.webkit.messageHandlers.alphaTabBridge.postMessage({
                                type: 'playedNote',
                                midi: beat.notes[i].realValue
                            });
                        }
                    }
                });

                window.api = {
                    play: function() { api.playPause(); },
                    pause: function() { api.pause(); },
                    setTempo: function(bpm) { 
                        api.playbackSpeed = bpm / 120; // AlphaTab usa multiplicador baseado no tempo original
                    }
                };
            </script>
        </body>
        </html>
        """
    }
}
