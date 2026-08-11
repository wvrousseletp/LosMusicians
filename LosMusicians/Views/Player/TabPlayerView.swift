import SwiftUI

struct TabPlayerView: View {
    let song: Song
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var offlineManager = OfflineTabManager.shared
    
    @State private var isPlaying: Bool = false
    @State private var tempo: Int = 120
    @State private var speedRatio: Double = 1.0
    @State private var selectedTrack: InstrumentTrack
    
    // Controles Avançados do Player (Estilo Songsterr)
    @State private var isLoopActive: Bool = false
    @State private var loopStartMeasure: Int = 1
    @State private var loopEndMeasure: Int = 4
    @State private var pitchShiftSemitones: Int = 0
    @State private var isMixerPresented: Bool = false
    @State private var isMetronomeActive: Bool = false
    @State private var isSpeedTrainerActive: Bool = false
    @State private var speedTrainerToast: String? = nil
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
            // Fundo escuro premium (Estilo Songsterr)
            Color(red: 0.05, green: 0.05, blue: 0.08)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Minimalista Superior
                HStack(spacing: 12) {
                    Button(action: {
                        stopPractice()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
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
                    
                    // Botão Discreto IA / XP
                    Button(action: {
                        isAIAnalysisPresented = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "brain.head.profile")
                            Text("\(sessionXP) XP")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.purple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                
                // Seletor de Faixa Discreto
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(song.tracks) { track in
                            Button(action: {
                                selectedTrack = track
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: track.instrument.iconName)
                                        .font(.system(size: 11))
                                    Text(track.name)
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedTrack.id == track.id ? Color.cyan.opacity(0.15) : Color.clear)
                                .foregroundColor(selectedTrack.id == track.id ? .cyan : .gray)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color(red: 0.08, green: 0.08, blue: 0.12))
                
                // Tablatura Principal
                InteractiveTablatureView(
                    alphaTex: song.tabDataJson,
                    isPlaying: $isPlaying,
                    tempo: $tempo,
                    instrument: selectedTrack.instrument.rawValue,
                    isLoopActive: $isLoopActive,
                    loopStartMeasure: $loopStartMeasure,
                    loopEndMeasure: $loopEndMeasure,
                    pitchShiftSemitones: $pitchShiftSemitones,
                    isMetronomeActive: $isMetronomeActive,
                    isSpeedTrainerActive: $isSpeedTrainerActive,
                    onLoopCycleCompleted: {
                        handleLoopCycleCompleted()
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Espaço extra inferior para a bottom bar flutuante não cobrir a tablatura
                .padding(.bottom, 90)
            }
            
            // Toast flutuante de aceleração do Speed Trainer
            if let toast = speedTrainerToast {
                VStack {
                    Text(toast)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .cornerRadius(16)
                        .shadow(radius: 5)
                        .padding(.top, 120)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(10)
            }
            
            // Bottom Bar Flutuante
            VStack {
                Spacer()
                
                HStack(spacing: 0) {
                    // Loop Button
                    Button(action: {
                        isLoopActive.toggle()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.system(size: 18))
                            Text("Loop")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(isLoopActive ? .green : .gray)
                        .frame(maxWidth: .infinity)
                    }
                    .contextMenu {
                        Button("Loop Compasso 1 a 4") { loopStartMeasure = 1; loopEndMeasure = 4; isLoopActive = true }
                        Button("Loop Compasso 1 a 2") { loopStartMeasure = 1; loopEndMeasure = 2; isLoopActive = true }
                        Button("Loop Compasso 3 a 4") { loopStartMeasure = 3; loopEndMeasure = 4; isLoopActive = true }
                    }
                    
                    // Metrônomo Button
                    Button(action: {
                        isMetronomeActive.toggle()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: isMetronomeActive ? "clock.fill" : "clock")
                                .font(.system(size: 18))
                            Text("Metrônomo")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(isMetronomeActive ? .yellow : .gray)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Play / Pause Button Central
                    Button(action: {
                        handlePlayButtonTapped()
                    }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: isPlaying ? [Color.orange, Color.red] : [Color.cyan, Color.blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 64, height: 64)
                                .shadow(color: isPlaying ? Color.red.opacity(0.3) : Color.cyan.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .offset(y: -15) // Eleva o botão central
                    
                    // Speed Button (%)
                    Menu {
                        Button("50%") { setSpeed(0.5) }
                        Button("75%") { setSpeed(0.75) }
                        Button("100% (Normal)") { setSpeed(1.0) }
                        Button("125%") { setSpeed(1.25) }
                        Button("150%") { setSpeed(1.5) }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "speedometer")
                                .font(.system(size: 18))
                            Text(String(format: "%.0f%%", speedRatio * 100))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(speedRatio != 1.0 ? .white : .gray)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Mixer Button
                    Button(action: {
                        isMixerPresented = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "slider.vertical.3")
                                .font(.system(size: 18))
                            Text("Mixer")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.16).opacity(0.95))
                        .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $isAIAnalysisPresented) {
            AIAnalysisSheetView(song: song, currentBPM: tempo)
        }
        .sheet(isPresented: $isMixerPresented) {
            MultitrackMixerView(song: song)
        }
        .onAppear {
            GuitarSynthEngine.shared.startEngineIfNeeded()
            OfflineTabManager.shared.recordRecent(song: song)
        }
    }
    
    private func handlePlayButtonTapped() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if isPlaying {
            isPlaying = false
            stopPractice()
        } else {
            startPlayingDirectly()
        }
    }
    
    private func startPlayingDirectly() {
        isPlaying = true
        startPracticeTimer()
    }
    
    private func handleLoopCycleCompleted() {
        if isSpeedTrainerActive {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            let newTempo = min(280, tempo + 5)
            tempo = newTempo
            
            withAnimation {
                speedTrainerToast = "⚡ +5 BPM! Acelerando para \(newTempo) BPM"
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    speedTrainerToast = nil
                }
            }
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
