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
                if let type = dict["type"] as? String {
                    if type == "playedNote", let midi = dict["midi"] as? Int {
                        NotificationCenter.default.post(name: NSNotification.Name("AlphaTabPlayedNote"), object: nil, userInfo: ["midi": midi])
                    } else if type == "playerFinished" {
                        DispatchQueue.main.async {
                            self.parent.isPlaying = false
                        }
                    }
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
        
        // Habilita reprodução de áudio sem exigir toque direto no DOM do WebKit
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
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
        let playJS = isPlaying ? "if(window.api) { window.api.play(); } else { window.pendingPlay = true; }" : "if(window.api) { window.api.pause(); } else { window.pendingPlay = false; }"
        uiView.evaluateJavaScript(playJS)
        
        let tempoJS = "if(window.api) { window.api.setTempo(\(tempo)); }"
        uiView.evaluateJavaScript(tempoJS)
    }
    
    private func generateAlphaTabHTML(with tex: String?) -> String {
        var validTex = (tex ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Normaliza quebras de linha literais
        validTex = validTex
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\r", with: "")
            
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
                    padding: 12px;
                    overflow-x: hidden;
                }
                #loading {
                    text-align: center;
                    padding: 30px 10px;
                    color: #06B6D4;
                    font-size: 14px;
                    font-weight: 500;
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
                    font-size: 14px;
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
                
                var globalApi = null;
                var audioCtx = null;
                var currentBPM = 100;
                var isInternalPlaying = false;
                
                // Sintetizador WebAudio de contingência para garantir áudio instantâneo
                function playSynthNote(midiNote) {
                    try {
                        var AudioCtxClass = window.AudioContext || window.webkitAudioContext;
                        if (!audioCtx) {
                            audioCtx = new AudioCtxClass();
                        }
                        if (audioCtx.state === 'suspended') {
                            audioCtx.resume();
                        }
                        
                        var freq = 440 * Math.pow(2, (midiNote - 69) / 12);
                        var osc = audioCtx.createOscillator();
                        var gain = audioCtx.createGain();
                        
                        osc.type = 'triangle';
                        osc.frequency.setValueAtTime(freq, audioCtx.currentTime);
                        
                        gain.gain.setValueAtTime(0.4, audioCtx.currentTime);
                        gain.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + 0.5);
                        
                        osc.connect(gain);
                        gain.connect(audioCtx.destination);
                        
                        osc.start();
                        osc.stop(audioCtx.currentTime + 0.5);
                    } catch(e) {
                        console.log("Synth error:", e);
                    }
                }

                function initAlphaTab() {
                    try {
                        if (typeof alphaTab === 'undefined') {
                            setTimeout(initAlphaTab, 300);
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
                                enableCursor: true,
                                soundFont: 'https://cdn.jsdelivr.net/npm/@coderline/alphatab@latest/dist/soundfont/sonivox.sf2'
                            }
                        });

                        globalApi = api;

                        api.renderStarted.on(function() {
                            loadingEl.style.display = 'none';
                            wrapper.style.display = 'block';
                        });

                        api.playerReady.on(function() {
                            console.log("AlphaTab Player Ready!");
                            if (window.pendingPlay) {
                                window.api.play();
                                window.pendingPlay = false;
                            }
                        });

                        api.playerFinished.on(function() {
                            isInternalPlaying = false;
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.alphaTabBridge) {
                                window.webkit.messageHandlers.alphaTabBridge.postMessage({ type: 'playerFinished' });
                            }
                        });

                        api.playedBeat.on(function (beat) {
                            if (beat && beat.notes) {
                                for (var i = 0; i < beat.notes.length; i++) {
                                    var midiVal = beat.notes[i].realValue;
                                    
                                    // Emite áudio de retorno garantido
                                    playSynthNote(midiVal);
                                    
                                    // Notifica o app Swift sobre a nota para validação de microfone
                                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.alphaTabBridge) {
                                        window.webkit.messageHandlers.alphaTabBridge.postMessage({
                                            type: 'playedNote',
                                            midi: midiVal
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
                            play: function() {
                                isInternalPlaying = true;
                                try {
                                    if (audioCtx && audioCtx.state === 'suspended') {
                                        audioCtx.resume();
                                    }
                                } catch(e) {}
                                
                                if (api) {
                                    api.play();
                                }
                            },
                            pause: function() {
                                isInternalPlaying = false;
                                if (api) {
                                    api.pause();
                                }
                            },
                            setTempo: function(bpm) { 
                                currentBPM = bpm;
                                if (api) {
                                    api.playbackSpeed = bpm / 100;
                                }
                            }
                        };
                        
                        if (window.pendingPlay) {
                            window.api.play();
                            window.pendingPlay = false;
                        }

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
