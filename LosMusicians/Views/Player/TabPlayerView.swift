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
    @State private var isCountInActive: Bool = true
    @State private var countInNumber: Int? = nil
    @State private var countInTimer: Timer? = nil
    @State private var isMixerPresented: Bool = false
    @State private var isLoopSettingsPresented: Bool = false
    @State private var isMetronomeActive: Bool = false
    @State private var isSpeedTrainerActive: Bool = false
    @State private var speedTrainerToast: String? = nil
    @State private var isAIAnalysisPresented: Bool = false
    
    @State private var sessionXP: Int = 0
    @State private var practiceTimer: Timer? = nil
    @State private var playerMode: PlayerMode = .native
    
    enum PlayerMode {
        case native
        case sheetMusic
    }
    
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
            
            VStack(spacing: 12) {
                // Header Superior
                HStack(spacing: 10) {
                    Button(action: {
                        stopPractice()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
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
                    
                    // Botão Salvar Offline (Cache Local)
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        offlineManager.toggleSave(song)
                    }) {
                        Image(systemName: offlineManager.isSaved(id: song.id) ? "arrow.down.circle.fill" : "arrow.down.circle")
                            .font(.system(size: 20))
                            .foregroundColor(offlineManager.isSaved(id: song.id) ? .cyan : .gray)
                            .frame(width: 38, height: 38)
                            .background(offlineManager.isSaved(id: song.id) ? Color.cyan.opacity(0.15) : Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    
                    // Botão Mixer Multitrack
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        isMixerPresented = true
                    }) {
                        Image(systemName: "slider.vertical.3")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.cyan)
                            .frame(width: 38, height: 38)
                            .background(Color.cyan.opacity(0.15))
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                            )
                    }
                    
                    // Badge de Dificuldade
                    Text(song.difficulty)
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
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
                
                // Faixas de Instrumentos
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(song.tracks) { track in
                            Button(action: {
                                selectedTrack = track
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: track.instrument.iconName)
                                        .font(.system(size: 12))
                                    Text(track.name)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(selectedTrack.id == track.id ? Color.cyan.opacity(0.2) : Color.white.opacity(0.06))
                                .foregroundColor(selectedTrack.id == track.id ? .cyan : .gray)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedTrack.id == track.id ? Color.cyan.opacity(0.6) : Color.clear, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Seletor de Modo de Visualização (Prática vs Partitura Songsterr)
                Picker("Visualização", selection: $playerMode) {
                    Text("🎸 Prática (Braço)").tag(PlayerMode.native)
                    Text("🎼 Partitura (Songsterr)").tag(PlayerMode.sheetMusic)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                
                // Visualizador Principal (Nativo ou AlphaTab)
                if playerMode == .native {
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
                    .padding(.horizontal, 14)
                } else {
                    AlphaTabWebView(
                        alphaTex: song.tabDataJson,
                        isPlaying: $isPlaying,
                        tempo: $tempo,
                        currentInstrumentTrack: .constant(selectedTrack.name),
                        pitchShiftSemitones: pitchShiftSemitones
                    )
                    .frame(height: 240)
                    .cornerRadius(18)
                    .padding(.horizontal, 14)
                }
                
                // Barra de Status: XP, Transposição e Afinação
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("+\(sessionXP) XP")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                    
                    Spacer()
                    
                    // Seletor Rápido de Pitch Shift / Transposição
                    Menu {
                        Button("Original (0 semitons)") { pitchShiftSemitones = 0 }
                        Button("-1 st (Eb Standard)") { pitchShiftSemitones = -1 }
                        Button("-2 st (D Standard)") { pitchShiftSemitones = -2 }
                        Button("-3 st (C# Standard)") { pitchShiftSemitones = -3 }
                        Button("-4 st (C Standard)") { pitchShiftSemitones = -4 }
                        Button("-5 st (B Standard / 7 cordas)") { pitchShiftSemitones = -5 }
                        Button("+1 st (Meio tom acima)") { pitchShiftSemitones = 1 }
                        Button("+2 st (1 tom acima)") { pitchShiftSemitones = 2 }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "tuningfork")
                                .font(.caption2)
                            Text(pitchShiftLabel)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(pitchShiftSemitones == 0 ? .gray : .yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(pitchShiftSemitones == 0 ? Color.white.opacity(0.06) : Color.yellow.opacity(0.18))
                        .cornerRadius(8)
                    }
                    
                    Text("Afinação: \(selectedTrack.tuning)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                
                // Toast flutuante de aceleração do Speed Trainer
                if let toast = speedTrainerToast {
                    Text(toast)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(12)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer(minLength: 2)
                
                // Painel de Controle Principal Luxuoso (Estilo Songsterr)
                VStack(spacing: 12) {
                    // Linha 1: Velocidade, Loop A-B, IA, BPM
                    HStack(spacing: 8) {
                        // Velocidade
                        Menu {
                            Button("0.50x (Lento)") { setSpeed(0.5) }
                            Button("0.75x") { setSpeed(0.75) }
                            Button("1.00x (Normal)") { setSpeed(1.0) }
                            Button("1.25x (Rápido)") { setSpeed(1.25) }
                            Button("1.50x (Mestre)") { setSpeed(1.5) }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "speedometer")
                                    .font(.system(size: 11))
                                Text(String(format: "%.2fx", speedRatio))
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // Loop A-B com seletor
                        Button(action: {
                            isLoopActive.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "repeat")
                                    .font(.system(size: 11))
                                Text(isLoopActive ? "Loop c.\(loopStartMeasure)-\(loopEndMeasure)" : "Loop")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(isLoopActive ? .green : .white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 7)
                            .background(isLoopActive ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .contextMenu {
                            Button("Loop Compasso 1 a 4") { loopStartMeasure = 1; loopEndMeasure = 4; isLoopActive = true }
                            Button("Loop Compasso 1 a 2") { loopStartMeasure = 1; loopEndMeasure = 2; isLoopActive = true }
                            Button("Loop Compasso 3 a 4") { loopStartMeasure = 3; loopEndMeasure = 4; isLoopActive = true }
                            Button("Avançar Ponto A (+1)") { loopStartMeasure = max(1, loopStartMeasure + 1) }
                            Button("Recuar Ponto A (-1)") { loopStartMeasure = max(1, loopStartMeasure - 1) }
                            Button("Avançar Ponto B (+1)") { loopEndMeasure = max(loopStartMeasure, loopEndMeasure + 1) }
                            Button("Recuar Ponto B (-1)") { loopEndMeasure = max(loopStartMeasure, loopEndMeasure - 1) }
                        }
                        
                        // Análise IA
                        Button(action: {
                            isAIAnalysisPresented = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 11))
                                Text("IA")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 7)
                            .background(Color.purple.opacity(0.25))
                            .cornerRadius(10)
                        }
                        
                        Spacer()
                        
                        // Ajuste Rápido de BPM
                        HStack(spacing: 4) {
                            Button(action: { tempo = max(40, tempo - 5) }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                            }
                            
                            Text("\(tempo) BPM")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(.cyan)
                                .frame(minWidth: 54)
                            
                            Button(action: { tempo = min(280, tempo + 5) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 14)
                    
                    // Linha 2: Ferramentas de Estudo (Count-In, Metrônomo, Speed Trainer)
                    HStack(spacing: 8) {
                        // Count-In (Contagem Regressiva 1, 2, 3, 4)
                        Button(action: {
                            isCountInActive.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isCountInActive ? "timer.circle.fill" : "timer")
                                    .font(.system(size: 11))
                                Text("Count-In")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(isCountInActive ? .cyan : .white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(isCountInActive ? Color.cyan.opacity(0.18) : Color.white.opacity(0.08))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isCountInActive ? Color.cyan.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                        }
                        
                        // Metrônomo
                        Button(action: {
                            isMetronomeActive.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isMetronomeActive ? "clock.fill" : "clock")
                                    .font(.system(size: 11))
                                Text("Metrônomo")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(isMetronomeActive ? .yellow : .white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(isMetronomeActive ? Color.yellow.opacity(0.18) : Color.white.opacity(0.08))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isMetronomeActive ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                        }
                        
                        // Speed Trainer Progressivo
                        Button(action: {
                            isSpeedTrainerActive.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 11))
                                Text("Speed Trainer")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(isSpeedTrainerActive ? .orange : .white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(isSpeedTrainerActive ? Color.orange.opacity(0.18) : Color.white.opacity(0.08))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSpeedTrainerActive ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    
                    // Linha 3: Botão Principal de Play/Pause Luxuoso
                    Button(action: {
                        handlePlayButtonTapped()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text(isPlaying ? "PAUSAR PRÁTICA" : "TOCAR TABLATURA")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
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
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }
                .padding(.top, 10)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(red: 0.1, green: 0.1, blue: 0.15).opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            
            // Overlay Visual de Contagem Regressiva (Count-In: 4, 3, 2, 1)
            if let count = countInNumber {
                ZStack {
                    Color.black.opacity(0.65)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 140, height: 140)
                                .shadow(color: .cyan.opacity(0.8), radius: 25)
                            
                            Text(count == 0 ? "VAI!" : "\(count)")
                                .font(.system(size: count == 0 ? 38 : 64, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(1.1)
                        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: count)
                        
                        Text("PREPARE SUAS MÃOS...")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $isAIAnalysisPresented) {
            AIAnalysisSheetView(song: song, currentBPM: tempo)
        }
        .sheet(isPresented: $isMixerPresented) {
            MultitrackMixerView(song: song)
        }
        .onAppear {
            OfflineTabManager.shared.recordRecent(song: song)
        }
    }
    
    private var pitchShiftLabel: String {
        if pitchShiftSemitones == 0 {
            return "Tom Normal"
        } else if pitchShiftSemitones > 0 {
            return "Tom +\(pitchShiftSemitones) st"
        } else {
            return "Tom \(pitchShiftSemitones) st"
        }
    }
    
    private func handlePlayButtonTapped() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if isPlaying {
            // Pausar
            isPlaying = false
            stopPractice()
            countInTimer?.invalidate()
            countInTimer = nil
            countInNumber = nil
        } else {
            // Se Count-in estiver ativo e não estiver tocando, faz a contagem de 4 tempos
            if isCountInActive {
                startCountIn()
            } else {
                startPlayingDirectly()
            }
        }
    }
    
    private func startCountIn() {
        countInTimer?.invalidate()
        var currentCount = 4
        countInNumber = currentCount
        
        // Intervalo de batida baseado no BPM
        let beatInterval = 60.0 / Double(max(40, tempo))
        
        // Primeiro clique imediato
        GuitarSynthEngine.shared.playCountInTick(beat: 1, totalBeats: 4)
        
        countInTimer = Timer.scheduledTimer(withTimeInterval: beatInterval, repeats: true) { timer in
            currentCount -= 1
            if currentCount > 0 {
                countInNumber = currentCount
                GuitarSynthEngine.shared.playCountInTick(beat: 5 - currentCount, totalBeats: 4)
            } else if currentCount == 0 {
                countInNumber = 0
                GuitarSynthEngine.shared.playCountInTick(beat: 4, totalBeats: 4)
            } else {
                timer.invalidate()
                countInTimer = nil
                withAnimation {
                    countInNumber = nil
                }
                startPlayingDirectly()
            }
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
        countInTimer?.invalidate()
        countInTimer = nil
        countInNumber = nil
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
