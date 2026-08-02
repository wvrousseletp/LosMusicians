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
        webView.scrollView.bounces = true
        
        let htmlContent = generateAlphaTabHTML(with: alphaTex)
        webView.loadHTMLString(htmlContent, baseURL: URL(string: "https://cdn.jsdelivr.net/"))
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let playJS = isPlaying ? "if(window.api) window.api.play();" : "if(window.api) window.api.pause();"
        uiView.evaluateJavaScript(playJS)
        
        let tempoJS = "if(window.api) window.api.setTempo(\(tempo));"
        uiView.evaluateJavaScript(tempoJS)
    }
    
    private func generateAlphaTabHTML(with tex: String?) -> String {
        var validTex = (tex ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if validTex.isEmpty || (!validTex.contains(":") && !validTex.contains(".")) {
            validTex = """
            \\title "Exercício IA"
            \\tempo 100
            .
            :8 5.6 7.6 8.6 7.6 5.5 7.5 8.5 7.5 | 5.4 7.4 8.4 7.4 5.3 7.3 8.3 7.3 | 5.2 7.2 8.2 7.2 5.1 7.1 8.1 7.1 | 8.1 7.1 5.1 7.1 8.2 7.2 5.2 7.2
            """
        }
        
        let escapedTex = validTex
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
                * { box-sizing: border-box; }
                body {
                    background-color: #0F0F13;
                    color: #FFFFFF;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    margin: 0;
                    padding: 8px;
                    overflow-x: hidden;
                }
                #loading {
                    text-align: center;
                    padding: 40px 10px;
                    color: #9CA3AF;
                    font-size: 14px;
                }
                #alphaTab {
                    width: 100%;
                    background: rgba(255, 255, 255, 0.03);
                    border-radius: 16px;
                    padding: 12px;
                    min-height: 280px;
                }
                .at-cursor-bar {
                    background: rgba(6, 182, 212, 0.25) !important;
                }
                .at-cursor-beat {
                    background: rgba(6, 182, 212, 0.5) !important;
                }
                .at-selection {
                    background: rgba(249, 115, 22, 0.2) !important;
                }
                .fallback-view {
                    padding: 16px;
                    background: #18181F;
                    border-radius: 12px;
                    border: 1px solid #272732;
                    font-family: monospace;
                    font-size: 13px;
                    color: #06B6D4;
                    white-space: pre-wrap;
                }
            </style>
        </head>
        <body>
            <div id="loading">Carregando partitura interativa...</div>
            <div id="alphaTab" style="display: none;"></div>

            <script>
                var wrapper = document.getElementById('alphaTab');
                var loadingEl = document.getElementById('loading');
                var texData = "\(escapedTex)";
                var fallbackTex = "\\\\title \\"Exercicio\\" \\n \\\\tempo 100 \\n . \\n :8 5.6 7.6 8.6 7.6 5.5 7.5 8.5 7.5 | 5.4 7.4 8.4 7.4 5.3 7.3 8.3 7.3 | 5.2 7.2 8.2 7.2 5.1 7.1 8.1 7.1 | 8.1 7.1 5.1 7.1 8.2 7.2 5.2 7.2";
                
                function initAlphaTab() {
                    try {
                        if (typeof alphaTab === 'undefined') {
                            showFallback("Biblioteca de partitura carregando...");
                            setTimeout(initAlphaTab, 500);
                            return;
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
                                enableUserInteraction: true,
                                soundFont: 'https://cdn.jsdelivr.net/npm/@coderline/alphatab@latest/dist/soundfont/sonivox.sf2'
                            }
                        });

                        api.renderStarted.on(function() {
                            loadingEl.style.display = 'none';
                            wrapper.style.display = 'block';
                        });

                        api.playedBeat.on(function (beat) {
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.alphaTabBridge) {
                                if (beat && beat.notes) {
                                    for (var i = 0; i < beat.notes.length; i++) {
                                        window.webkit.messageHandlers.alphaTabBridge.postMessage({
                                            type: 'playedNote',
                                            midi: beat.notes[i].realValue
                                        });
                                    }
                                }
                            }
                        });

                        try {
                            api.tex(texData);
                        } catch (err) {
                            console.warn("AlphaTex erro, usando fallback:", err);
                            api.tex(fallbackTex);
                        }

                        window.api = {
                            play: function() { api.playPause(); },
                            pause: function() { api.pause(); },
                            setTempo: function(bpm) { 
                                api.playbackSpeed = bpm / 100;
                            }
                        };
                    } catch (e) {
                        showFallback(texData);
                    }
                }

                function showFallback(text) {
                    loadingEl.style.display = 'none';
                    wrapper.style.display = 'block';
                    wrapper.innerHTML = '<div class="fallback-view"><strong>🎵 Exercício Gerado:</strong><br><br>' + text + '</div>';
                }

                if (document.readyState === 'complete' || document.readyState === 'interactive') {
                    initAlphaTab();
                } else {
                    window.addEventListener('DOMContentLoaded', initAlphaTab);
                }
            </script>
        </body>
        </html>
        """
    }
}
