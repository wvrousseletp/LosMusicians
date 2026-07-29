import SwiftUI

struct TabPlayerView: View {
    let song: Song
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    
    @State private var isPlaying: Bool = false
    @State private var tempo: Int = 120
    @State private var speedRatio: Double = 1.0 // 0.5x, 0.75x, 1.0x, 1.25x
    @State private var selectedTrack: InstrumentTrack
    @State private var isLoopActive: Bool = false
    @State private var isAIAnalysisPresented: Bool = false
    @State private var sessionXP: Int = 0
    @State private var practiceTimer: Timer? = nil
    
    init(song: Song) {
        self.song = song
        _tempo = State(initialValue: song.bpm)
        _selectedTrack = State(initialValue: song.tracks.first ?? InstrumentTrack(id: "t0", name: "Guitarra", instrument: .leadGuitar))
    }
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color.black]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Button(action: {
                        stopPracticeTimer()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Difficulty Badge
                    Text(song.difficulty)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(difficultyColor(song.difficulty).opacity(0.2))
                        .foregroundColor(difficultyColor(song.difficulty))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(difficultyColor(song.difficulty), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Track / Instrument Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(song.tracks) { track in
                            Button(action: {
                                selectedTrack = track
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: track.instrument.iconName)
                                    Text(track.name)
                                        .font(.caption.bold())
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedTrack.id == track.id ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
                                .foregroundColor(selectedTrack.id == track.id ? .cyan : .gray)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedTrack.id == track.id ? Color.cyan : Color.clear, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Tablature Display
                AlphaTabWebView(isPlaying: $isPlaying, tempo: $tempo, currentInstrumentTrack: $selectedTrack.name)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(16)
                    .padding(.horizontal)
                
                // Gamification Session Live XP Counter
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("XP Ganho na Sessão: +\(sessionXP) XP")
                        .font(.footnote.bold())
                        .foregroundColor(.yellow)
                    Spacer()
                    Text("Afinação: \(selectedTrack.tuning)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 24)
                
                // Control Panel Bar (Songsterr style)
                VStack(spacing: 16) {
                    // Speed Control & Loop Controls
                    HStack(spacing: 20) {
                        // Speed selector button
                        Menu {
                            Button("0.5x (Lento)") { setSpeed(0.5) }
                            Button("0.75x") { setSpeed(0.75) }
                            Button("1.0x (Normal)") { setSpeed(1.0) }
                            Button("1.25x (Rápido)") { setSpeed(1.25) }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "speedometer")
                                Text("\(String(format: "%.2fx", speedRatio))")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(10)
                        }
                        
                        // Loop A-B Toggle
                        Button(action: {
                            isLoopActive.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "repeat")
                                Text("Loop A-B")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(isLoopActive ? .green : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isLoopActive ? Color.green.opacity(0.2) : Color.white.opacity(0.12))
                            .cornerRadius(10)
                        }
                        
                        // AI Analysis Button 🤖
                        Button(action: {
                            isAIAnalysisPresented = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "brain.head.profile")
                                Text("Análise IA")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.purple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.purple.opacity(0.25))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                            )
                        }
                        
                        Spacer()
                        
                        // BPM Indicator
                        Text("\(tempo) BPM")
                            .font(.subheadline.bold())
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 24)
                    
                    // Main Play/Pause Button
                    Button(action: {
                        isPlaying.toggle()
                        if isPlaying {
                            startPracticeTimer()
                        } else {
                            stopPracticeTimer()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                            Text(isPlaying ? "PAUSAR PRÁTICA" : "TOCAR TABLATURA")
                                .font(.headline.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: isPlaying ? [Color.orange, Color.red] : [Color.cyan, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: isPlaying ? Color.red.opacity(0.4) : Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
                .background(Color.black.opacity(0.4))
                .cornerRadius(24)
            }
        }
        .sheet(isPresented: $isAIAnalysisPresented) {
            AIAnalysisSheetView(song: song, currentBPM: tempo)
        }
    }
    
    private func setSpeed(_ ratio: Double) {
        speedRatio = ratio
        tempo = Int(Double(song.bpm) * ratio)
    }
    
    private func startPracticeTimer() {
        practiceTimer?.invalidate()
        practiceTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { _ in
            // Ganha 1 XP a cada 6 segundos de reprodução ativa
            sessionXP += 1
            authManager.addPracticeTime(minutes: 1)
        }
    }
    
    private func stopPracticeTimer() {
        practiceTimer?.invalidate()
        practiceTimer = nil
    }
    
    private func difficultyColor(_ diff: String) -> Color {
        switch diff.lowercased() {
        case "fácil": return .green
        case "médio": return .yellow
        case "difícil": return .orange
        default: return .red
        }
    }
}

// MARK: - Modal de Análise de IA
struct AIAnalysisSheetView: View {
    let song: Song
    let currentBPM: Int
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    
    @State private var isAnalyzing: Bool = true
    @State private var analysisProgress: Double = 0.0
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Drag handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title)
                        .foregroundColor(.purple)
                    Text("Análise de Desempenho por IA")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                
                if isAnalyzing {
                    VStack(spacing: 20) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                        
                        Text("Analisando padrão rítmico, digitação e articulação em \(currentBPM) BPM...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    }
                    .onAppear {
                        // Simula processamento de IA em 1.5s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                isAnalyzing = false
                                authManager.addPracticeTime(minutes: 5) // Bonus XP por usar analise de IA!
                            }
                        }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Overall Score Card
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Pontuação da Execução")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("92 / 100")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.green)
                                }
                                Spacer()
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(16)
                            
                            // Insights / Recomendações
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recomendações Personalizadas da IA:")
                                    .font(.headline)
                                    .foregroundColor(.purple)
                                
                                DicasIARow(icon: "metronome", color: .cyan, title: "Consistência de Tempo", desc: "Sua precisão no andamento em \(currentBPM) BPM está excelente. Tente acelerar para \(Int(Double(currentBPM) * 1.1)) BPM para criar margem de segurança.")
                                
                                DicasIARow(icon: "hand.point.up.left.fill", color: .orange, title: "Economia de Movimento", desc: "No solo de \(song.title), mantenha os dedos mais próximos da escala durante as trocas rápidas de corda.")
                                
                                DicasIARow(icon: "sparkles", color: .yellow, title: "Articulação de Legato", desc: "Destaque as notas abafadas (palm mute) nos compassos de transição para maior clareza sonora.")
                            }
                            
                            // Recompensa XP
                            HStack {
                                Image(systemName: "gift.fill")
                                    .foregroundColor(.yellow)
                                Text("Bônus da IA Aplicado: +25 XP adicionados ao seu perfil!")
                                    .font(.footnote.bold())
                                    .foregroundColor(.yellow)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.yellow.opacity(0.15))
                            .cornerRadius(12)
                            
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("ENTENDIDO E CONTINUAR TREINO")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(16)
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct DicasIARow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(desc)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
}
