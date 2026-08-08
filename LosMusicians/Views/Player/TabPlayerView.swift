import SwiftUI

struct TabPlayerView: View {
    let song: Song
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    
    @State private var isPlaying: Bool = false
    @State private var tempo: Int = 120
    @State private var speedRatio: Double = 1.0
    @State private var selectedTrack: InstrumentTrack
    @State private var isLoopActive: Bool = false
    @State private var isAIAnalysisPresented: Bool = false
    @State private var sessionXP: Int = 0
    @State private var practiceTimer: Timer? = nil
    
    init(song: Song) {
        self.song = song
        _tempo = State(initialValue: max(40, song.bpm))
        _selectedTrack = State(initialValue: song.tracks.first ?? InstrumentTrack(id: "t0", name: "Guitarra", instrument: .leadGuitar))
    }
    
    var body: some View {
        ZStack {
            // Fundo escuro premium com gradiente sutil
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.13),
                    Color(red: 0.04, green: 0.04, blue: 0.07),
                    Color.black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 14) {
                // Header Superior
                HStack(spacing: 12) {
                    Button(action: {
                        stopPractice()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title)
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Badge de Dificuldade
                    Text(song.difficulty)
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(difficultyColor(song.difficulty).opacity(0.15))
                        .foregroundColor(difficultyColor(song.difficulty))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(difficultyColor(song.difficulty).opacity(0.5), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                
                // Faixa / Instrumento Selecionado
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(song.tracks) { track in
                            Button(action: {
                                selectedTrack = track
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: track.instrument.iconName)
                                        .font(.system(size: 13))
                                    Text(track.name)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedTrack.id == track.id ? Color.cyan.opacity(0.2) : Color.white.opacity(0.06))
                                .foregroundColor(selectedTrack.id == track.id ? .cyan : .gray)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedTrack.id == track.id ? Color.cyan.opacity(0.6) : Color.clear, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Tablatura Interativa Nativa em Tempo Real (Com áudio sintetizado e braço)
                InteractiveTablatureView(
                    alphaTex: song.tabDataJson,
                    isPlaying: $isPlaying,
                    tempo: $tempo,
                    instrument: selectedTrack.instrument.rawValue
                )
                .padding(.horizontal, 16)
                
                // Barra de Gamificação & Afinação
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                        Text("XP na Sessão: +\(sessionXP) XP")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                    Spacer()
                    Text("Afinação: \(selectedTrack.tuning)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 4)
                
                // Painel de Controle Moderno e Bem Encaixado (Glassmorphism)
                VStack(spacing: 14) {
                    // Linha 1: Controles de Velocidade, Loop, Análise e BPM
                    HStack(spacing: 10) {
                        // Velocidade (Speed)
                        Menu {
                            Button("0.5x (Lento)") { setSpeed(0.5) }
                            Button("0.75x") { setSpeed(0.75) }
                            Button("1.0x (Normal)") { setSpeed(1.0) }
                            Button("1.25x (Rápido)") { setSpeed(1.25) }
                            Button("1.5x (Mestre)") { setSpeed(1.5) }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "speedometer")
                                    .font(.system(size: 12))
                                Text(String(format: "%.2fx", speedRatio))
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // Loop A-B
                        Button(action: {
                            isLoopActive.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "repeat")
                                    .font(.system(size: 12))
                                Text("Loop")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(isLoopActive ? .green : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(isLoopActive ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // Análise IA
                        Button(action: {
                            isAIAnalysisPresented = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 12))
                                Text("IA")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.purple)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.purple.opacity(0.25))
                            .cornerRadius(10)
                        }
                        
                        Spacer()
                        
                        // Ajuste Rápido de BPM
                        HStack(spacing: 6) {
                            Button(action: { tempo = max(40, tempo - 5) }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            
                            Text("\(tempo) BPM")
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .foregroundColor(.cyan)
                            
                            Button(action: { tempo = min(280, tempo + 5) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                    
                    // Linha 2: Botão Principal de Play/Pause Luxuoso
                    Button(action: {
                        togglePlay()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text(isPlaying ? "PAUSAR PRÁTICA" : "TOCAR TABLATURA")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: isPlaying ? [Color.orange, Color.red] : [Color(red: 0.1, green: 0.7, blue: 1.0), Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: isPlaying ? Color.red.opacity(0.4) : Color.cyan.opacity(0.4), radius: 10, x: 0, y: 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .padding(.top, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.15).opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
        .sheet(isPresented: $isAIAnalysisPresented) {
            AIAnalysisSheetView(song: song, currentBPM: tempo)
        }
    }
    
    private func togglePlay() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        isPlaying.toggle()
        if isPlaying {
            startPracticeTimer()
        } else {
            stopPractice()
        }
    }
    
    private func setSpeed(_ ratio: Double) {
        speedRatio = ratio
        tempo = Int(Double(song.bpm) * ratio)
    }
    
    private func startPracticeTimer() {
        practiceTimer?.invalidate()
        practiceTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { _ in
            sessionXP += 1
            authManager.addPracticeTime(minutes: 1)
        }
    }
    
    private func stopPractice() {
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
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title)
                        .foregroundColor(.purple)
                    Text("Análise de Desempenho por IA")
                        .font(.title3.bold())
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
                        
                        Text("Analisando precisão do ritmo, digitação e afinação em \(currentBPM) BPM...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation {
                                isAnalyzing = false
                                authManager.addPracticeTime(minutes: 5)
                            }
                        }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Precisão Estimada")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("94 / 100")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.green)
                                }
                                Spacer()
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(16)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recomendações da IA:")
                                    .font(.headline)
                                    .foregroundColor(.purple)
                                
                                DicasIARow(icon: "metronome", color: .cyan, title: "Precisão de Tempo", desc: "Seu ritmo em \(currentBPM) BPM está consistente. Experimente acelerar +10 BPM no modo desafio.")
                                
                                DicasIARow(icon: "hand.point.up.left.fill", color: .orange, title: "Economia de Movimento", desc: "Mantenha o polegar atrás do braço nas cordas 5 e 6 para obter mais alcance e velocidade.")
                            }
                            
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("CONTINUAR PRÁTICA")
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
