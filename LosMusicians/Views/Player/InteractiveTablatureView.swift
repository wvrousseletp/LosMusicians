import SwiftUI

// MARK: - Modelo de Nota da Tablatura
struct TabNoteItem: Identifiable, Equatable {
    let id = UUID()
    let string: Int      // 1 (mais aguda) a 6 (mais grave)
    let fret: Int        // 0 a 24
    let durationBeats: Double // 0.5 = colcheia (8th), 1.0 = semínima (4th)
    let measureIndex: Int
    let noteIndex: Int
    
    func midiValue(pitchShift: Int = 0) -> Int {
        let openMidiByString: [Int: Int] = [
            6: 40, // E2
            5: 45, // A2
            4: 50, // D3
            3: 55, // G3
            2: 59, // B3
            1: 64  // E4
        ]
        return (openMidiByString[string] ?? 40) + fret + pitchShift
    }
    
    func noteName(pitchShift: Int = 0) -> String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let m = midiValue(pitchShift: pitchShift)
        let noteIndex = (m % 12 + 12) % 12
        let octave = (m / 12) - 1
        return "\(noteNames[noteIndex])\(octave)"
    }
}

// MARK: - Modelo de Compasso (Measure)
struct TabMeasure: Identifiable, Equatable {
    let id = UUID()
    let index: Int
    var notes: [TabNoteItem]
}

// MARK: - Parser de Tablatura (AlphaTex e formato universal)
struct TabParser {
    static func parse(alphaTex: String?) -> ([TabNoteItem], [TabMeasure]) {
        var rawText = (alphaTex ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if rawText.isEmpty {
            rawText = ":8 5.6 7.6 8.6 7.6 5.5 7.5 8.5 7.5 | 5.4 7.4 8.4 7.4 5.3 7.3 8.3 7.3 | 5.2 7.2 8.2 7.2 5.1 7.1 8.1 7.1 | 8.1 7.1 5.1 7.1 8.2 7.2 5.2 7.2"
        }
        
        // Normaliza quebras de linha literais
        rawText = rawText
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\r", with: "")
        
        let lines = rawText.components(separatedBy: .newlines)
        var tabLines: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.hasPrefix("\\") && trimmed != "." && !trimmed.isEmpty {
                tabLines.append(trimmed)
            }
        }
        
        let tabBody = tabLines.joined(separator: " ")
        let tokens = tabBody.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        var notes: [TabNoteItem] = []
        var currentDuration: Double = 0.5
        var currentMeasure = 1
        var noteCounter = 0
        
        for token in tokens {
            if token == "|" {
                currentMeasure += 1
                continue
            }
            
            if token.hasPrefix(":") {
                let durStr = token.dropFirst()
                if let durNum = Double(durStr) {
                    currentDuration = 4.0 / durNum
                }
                continue
            }
            
            // Trata notas no padrão Fret.Corda (ex: 5.6 -> casa 5 na corda 6)
            if token.contains(".") {
                let parts = token.components(separatedBy: ".")
                if parts.count == 2, let fret = Int(parts[0]), let string = Int(parts[1]) {
                    notes.append(TabNoteItem(
                        string: min(6, max(1, string)),
                        fret: max(0, fret),
                        durationBeats: currentDuration,
                        measureIndex: currentMeasure,
                        noteIndex: noteCounter
                    ))
                    noteCounter += 1
                }
            } else if let fret = Int(token) {
                notes.append(TabNoteItem(
                    string: 6,
                    fret: fret,
                    durationBeats: currentDuration,
                    measureIndex: currentMeasure,
                    noteIndex: noteCounter
                ))
                noteCounter += 1
            }
        }
        
        if notes.isEmpty {
            let defaultNotes = [
                (5, 6), (7, 6), (8, 6), (7, 6),
                (5, 5), (7, 5), (8, 5), (7, 5),
                (5, 4), (7, 4), (8, 4), (7, 4),
                (5, 3), (7, 3), (8, 3), (7, 3)
            ]
            for (idx, n) in defaultNotes.enumerated() {
                notes.append(TabNoteItem(
                    string: n.1,
                    fret: n.0,
                    durationBeats: 0.5,
                    measureIndex: (idx / 4) + 1,
                    noteIndex: idx
                ))
            }
        }
        
        // Agrupa em compassos
        var measuresDict: [Int: [TabNoteItem]] = [:]
        for note in notes {
            measuresDict[note.measureIndex, default: []].append(note)
        }
        
        let measures = measuresDict.keys.sorted().map { idx in
            TabMeasure(index: idx, notes: measuresDict[idx]!)
        }
        
        return (notes, measures)
    }
}

// MARK: - View Principal da Tablatura Interativa
struct InteractiveTablatureView: View {
    let alphaTex: String?
    @Binding var isPlaying: Bool
    @Binding var tempo: Int
    var instrument: String = "Guitarra"
    
    @Binding var isLoopActive: Bool
    @Binding var loopStartMeasure: Int
    @Binding var loopEndMeasure: Int
    @Binding var pitchShiftSemitones: Int
    @Binding var isMetronomeActive: Bool
    @Binding var isSpeedTrainerActive: Bool
    
    var onNotePlayed: ((Int) -> Void)? = nil
    var onLoopCycleCompleted: (() -> Void)? = nil
    
    init(
        alphaTex: String?,
        isPlaying: Binding<Bool>,
        tempo: Binding<Int>,
        instrument: String = "Guitarra",
        isLoopActive: Binding<Bool> = .constant(false),
        loopStartMeasure: Binding<Int> = .constant(1),
        loopEndMeasure: Binding<Int> = .constant(8),
        pitchShiftSemitones: Binding<Int> = .constant(0),
        isMetronomeActive: Binding<Bool> = .constant(false),
        isSpeedTrainerActive: Binding<Bool> = .constant(false),
        onNotePlayed: ((Int) -> Void)? = nil,
        onLoopCycleCompleted: (() -> Void)? = nil
    ) {
        self.alphaTex = alphaTex
        self._isPlaying = isPlaying
        self._tempo = tempo
        self.instrument = instrument
        self._isLoopActive = isLoopActive
        self._loopStartMeasure = loopStartMeasure
        self._loopEndMeasure = loopEndMeasure
        self._pitchShiftSemitones = pitchShiftSemitones
        self._isMetronomeActive = isMetronomeActive
        self._isSpeedTrainerActive = isSpeedTrainerActive
        self.onNotePlayed = onNotePlayed
        self.onLoopCycleCompleted = onLoopCycleCompleted
    }
    
    @State private var notes: [TabNoteItem] = []
    @State private var measures: [TabMeasure] = []
    @State private var currentActiveIndex: Int = -1
    @State private var playbackTimer: Timer? = nil
    @State private var showFretboard: Bool = true
    @State private var tickCounter: Int = 0
    
    private let stringNames = ["e", "B", "G", "D", "A", "E"]
    
    var totalMeasures: Int {
        notes.map { $0.measureIndex }.max() ?? 1
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Mini Braço de Guitarra Dinâmico (Fretboard Visualizer)
            if showFretboard {
                GuitarFretboardVisualizer(
                    activeNote: currentActiveIndex >= 0 && currentActiveIndex < notes.count ? notes[currentActiveIndex] : nil,
                    pitchShift: pitchShiftSemitones
                )
                .transition(.opacity.combined(with: .scale))
            }
            
            // Área da Tablatura - Rolagem Vertical Estilo Songsterr
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.09, green: 0.09, blue: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.4), Color.purple.opacity(0.2), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                
                VStack(alignment: .leading, spacing: 0) {
                    // Header Status
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isPlaying ? Color.red : Color.orange)
                                .frame(width: 8, height: 8)
                            Text(isPlaying ? "EM REPRODUÇÃO" : "MODO DE PRÁTICA")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(isPlaying ? .red : .orange)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        
                        if isLoopActive {
                            HStack(spacing: 4) {
                                Image(systemName: "repeat")
                                    .font(.caption2)
                                Text("A-B: c.\(loopStartMeasure)-\(loopEndMeasure)")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(6)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                showFretboard.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: showFretboard ? "eye.fill" : "eye.slash.fill")
                                Text("Braço")
                            }
                            .font(.caption2.bold())
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    // Grade Vertical com Compassos
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: true) {
                            LazyVStack(spacing: 36) {
                                ForEach(measures) { measure in
                                    let isMeasureActive = (currentActiveIndex >= 0 && currentActiveIndex < notes.count && notes[currentActiveIndex].measureIndex == measure.index)
                                    let isInLoop = !isLoopActive || (measure.index >= loopStartMeasure && measure.index <= loopEndMeasure)
                                    
                                    MeasureBlockView(
                                        measure: measure,
                                        stringNames: stringNames,
                                        isMeasureActive: isMeasureActive,
                                        isInLoop: isInLoop,
                                        currentActiveIndex: currentActiveIndex,
                                        pitchShift: pitchShiftSemitones,
                                        tempo: tempo,
                                        onNoteTap: { noteIndex in
                                            playSingleNote(index: noteIndex)
                                        }
                                    )
                                    .id(measure.index)
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 8)
                        }
                        .onChange(of: currentActiveIndex) { newIndex in
                            if newIndex >= 0 && newIndex < notes.count {
                                let activeMeasure = notes[newIndex].measureIndex
                                // Autoscroll vertical suave para o compasso ativo (Songsterr style)
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(activeMeasure, anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            let parsed = TabParser.parse(alphaTex: alphaTex)
            self.notes = parsed.0
            self.measures = parsed.1
            if loopEndMeasure == 1 && totalMeasures > 1 {
                loopEndMeasure = totalMeasures
            }
        }
        .onChange(of: alphaTex) { newTex in
            let parsed = TabParser.parse(alphaTex: newTex)
            self.notes = parsed.0
            self.measures = parsed.1
            if loopEndMeasure == 1 && totalMeasures > 1 {
                loopEndMeasure = totalMeasures
            }
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                startPlayback()
            } else {
                stopPlayback()
            }
        }
        .onChange(of: tempo) { _ in
            if isPlaying {
                startPlayback()
            }
        }
        .onChange(of: instrument) { _ in
            if isPlaying {
                startPlayback()
            }
        }
        .onChange(of: pitchShiftSemitones) { _ in
            GuitarSynthEngine.shared.pitchShiftSemitones = pitchShiftSemitones
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    private func playSingleNote(index: Int) {
        guard index >= 0 && index < notes.count else { return }
        currentActiveIndex = index
        let note = notes[index]
        let midi = note.midiValue(pitchShift: pitchShiftSemitones)
        
        GuitarSynthEngine.shared.playNote(midi: midi, instrument: instrument, pitchShift: pitchShiftSemitones)
        onNotePlayed?(midi)
    }
    
    private func startPlayback() {
        GuitarSynthEngine.shared.startEngineIfNeeded()
        playbackTimer?.invalidate()
        tickCounter = 0
        
        // Inicia na nota correta se houver loop
        if isLoopActive {
            if let firstNoteOfLoop = notes.firstIndex(where: { $0.measureIndex >= loopStartMeasure }) {
                currentActiveIndex = firstNoteOfLoop - 1
            } else {
                currentActiveIndex = -1
            }
        } else if currentActiveIndex < 0 || currentActiveIndex >= notes.count - 1 {
            currentActiveIndex = -1
        }
        
        let beatInterval = 60.0 / Double(max(30, tempo))
        let tickInterval = beatInterval * 0.5
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.isMetronomeActive {
                    if self.tickCounter % 2 == 0 {
                        let isStrongBeat = (self.tickCounter / 2) % 4 == 0
                        GuitarSynthEngine.shared.playMetronomeTick(isStrong: isStrongBeat)
                    }
                }
                self.tickCounter += 1
                
                var nextIndex = self.currentActiveIndex + 1
                
                // Trata loop
                if self.isLoopActive {
                    if nextIndex < self.notes.count && self.notes[nextIndex].measureIndex < self.loopStartMeasure {
                        if let firstInLoop = self.notes.firstIndex(where: { $0.measureIndex >= self.loopStartMeasure }) {
                            nextIndex = firstInLoop
                        }
                    }
                    if nextIndex >= self.notes.count || (nextIndex < self.notes.count && self.notes[nextIndex].measureIndex > self.loopEndMeasure) {
                        self.onLoopCycleCompleted?()
                        if let firstInLoop = self.notes.firstIndex(where: { $0.measureIndex >= self.loopStartMeasure }) {
                            nextIndex = firstInLoop
                        } else {
                            nextIndex = 0
                        }
                    }
                }
                
                if nextIndex < self.notes.count {
                    self.currentActiveIndex = nextIndex
                    let note = self.notes[nextIndex]
                    let midi = note.midiValue(pitchShift: self.pitchShiftSemitones)
                    
                    GuitarSynthEngine.shared.playNote(midi: midi, instrument: self.instrument, pitchShift: self.pitchShiftSemitones)
                    self.onNotePlayed?(midi)
                } else {
                    self.onLoopCycleCompleted?()
                    if self.isLoopActive {
                        self.currentActiveIndex = 0
                        self.startPlayback()
                    } else {
                        self.isPlaying = false
                        self.stopPlayback()
                    }
                }
            }
        }
    }
    
    private func stopPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        GuitarSynthEngine.shared.stopAll()
    }
}

// MARK: - Bloco de Compasso (Measure) Vertical Estilo Songsterr
struct MeasureBlockView: View {
    let measure: TabMeasure
    let stringNames: [String]
    let isMeasureActive: Bool
    let isInLoop: Bool
    let currentActiveIndex: Int
    let pitchShift: Int
    let tempo: Int
    let onNoteTap: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header do Compasso e Barras
            HStack {
                Text("\(measure.index)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isMeasureActive ? .red : .gray)
                    .frame(width: 24, height: 24)
                    .background(isMeasureActive ? Color.red.opacity(0.15) : Color.white.opacity(0.05))
                    .clipShape(Circle())
                
                if !isInLoop {
                    Text("Fora do Loop")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.6))
                }
                Spacer()
            }
            .padding(.leading, 8)
            
            // Corpo da Partitura
            ZStack(alignment: .leading) {
                // Fundo iluminado se ativo
                if isMeasureActive {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.04))
                }
                
                HStack(spacing: 0) {
                    // Coluna de nomes das cordas (Afinacao)
                    VStack(spacing: 16) {
                        ForEach(0..<6, id: \.self) { idx in
                            Text(stringNames[idx])
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray.opacity(0.9))
                                .frame(width: 24, height: 14)
                        }
                    }
                    .padding(.leading, 8)
                    
                    // Barra inicial de compasso
                    Divider()
                        .frame(width: 2, height: 120)
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal, 4)
                    
                    GeometryReader { geo in
                        // As 6 linhas da tablatura (Staff Lines)
                        VStack(spacing: 16) {
                            ForEach(1...6, id: \.self) { stringIndex in
                                Rectangle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 1.5)
                            }
                        }
                        .offset(y: 20) // Ajuste para centralizar as linhas no Measure
                        
                        let noteWidth = max(35.0, geo.size.width / CGFloat(max(measure.notes.count, 4)))
                        
                        // Notas e Hastes Rítmicas
                        HStack(spacing: 0) {
                            ForEach(measure.notes) { note in
                                let isNoteActive = (currentActiveIndex == note.noteIndex)
                                TabNoteNodeView(
                                    note: note,
                                    isActive: isNoteActive,
                                    isInLoopRange: isInLoop,
                                    pitchShift: pitchShift,
                                    onTap: { onNoteTap(note.noteIndex) }
                                )
                                .frame(width: noteWidth)
                            }
                            Spacer(minLength: 0)
                        }
                        
                        // O Playhead (Cursor Vermelho Vertical do Songsterr)
                        if isMeasureActive, let localIdx = measure.notes.firstIndex(where: { $0.noteIndex == currentActiveIndex }) {
                            let playheadX = CGFloat(localIdx) * noteWidth + (noteWidth / 2.0)
                            let tickInterval = (60.0 / Double(max(30, tempo))) * 0.5
                            
                            Rectangle()
                                .fill(LinearGradient(colors: [Color.red, Color.red.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 3, height: 150)
                                .shadow(color: Color.red, radius: 4, x: 0, y: 0)
                                .offset(x: playheadX - 1.5, y: 6)
                                .animation(.linear(duration: tickInterval), value: currentActiveIndex)
                        }
                    }
                    .frame(height: 160)
                    
                    // Barra final de compasso
                    Divider()
                        .frame(width: 2, height: 120)
                        .background(Color.white.opacity(0.2))
                }
            }
            .frame(height: 160)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isMeasureActive ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
            .opacity(isInLoop ? 1.0 : 0.4)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Nó da Nota e Haste Rítmica
struct TabNoteNodeView: View {
    let note: TabNoteItem
    let isActive: Bool
    let isInLoopRange: Bool
    let pitchShift: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Fret number / Note Circle
                ZStack {
                    // A distância vertical exata baseada na corda. 
                    // Espaçamento de 16pt entre cordas. Corda 1 no topo.
                    let yOffset = CGFloat(note.string - 1) * 17.5 - 44
                    
                    ZStack {
                        // Background do número na corda (para não mostrar a linha por baixo)
                        Rectangle()
                            .fill(Color(red: 0.09, green: 0.09, blue: 0.12))
                            .frame(width: 22, height: 22)
                        
                        if isActive {
                            Circle()
                                .fill(LinearGradient(colors: [Color.red, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 26, height: 26)
                                .shadow(color: Color.red.opacity(0.8), radius: 6)
                        }
                        
                        Text("\(note.fret)")
                            .font(.system(size: isActive ? 13 : 12, weight: .black, design: .rounded))
                            .foregroundColor(isActive ? .white : (isInLoopRange ? .white : .gray.opacity(0.5)))
                    }
                    .offset(y: yOffset + 24)
                    .scaleEffect(isActive ? 1.15 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isActive)
                }
                .frame(height: 110)
                
                // Rhythm Stem (Haste Rítmica embaixo da tablatura)
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(isActive ? Color.red : Color.gray.opacity(0.6))
                        .frame(width: 2, height: 25)
                    
                    // Se for colcheia (duration <= 0.5), adiciona uma perninha (beam/flag)
                    if note.durationBeats <= 0.5 {
                        Rectangle()
                            .fill(isActive ? Color.red : Color.gray.opacity(0.6))
                            .frame(width: 14, height: 3)
                            .offset(x: 0, y: 22) // Conecta no fim da haste
                    }
                }
                .frame(height: 35)
                .padding(.top, 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Braço da Guitarra Visualizador (Fretboard)
struct GuitarFretboardVisualizer: View {
    let activeNote: TabNoteItem?
    var pitchShift: Int = 0
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("🎸 BRAÇO DA GUITARRA")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                if let note = activeNote {
                    Text("Nota: \(note.noteName(pitchShift: pitchShift)) (Corda \(note.string), Casa \(note.fret))")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 16)
            
            ZStack(alignment: .leading) {
                // Corpo da Escala de Madeira Escura
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.16, green: 0.12, blue: 0.10), Color(red: 0.11, green: 0.08, blue: 0.07)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                
                // Trastes metálicos (Frets 0 a 15)
                HStack(spacing: 0) {
                    ForEach(0...15, id: \.self) { fretIdx in
                        Rectangle()
                            .fill(fretIdx == 0 ? Color.white.opacity(0.8) : Color.white.opacity(0.2))
                            .frame(width: fretIdx == 0 ? 3 : 1.5)
                        if fretIdx < 15 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 8)
                
                // Marcadores de escala (Inlays nas casas 3, 5, 7, 9, 12)
                GeometryReader { geo in
                    let step = (geo.size.width - 16) / 15.0
                    ForEach([3, 5, 7, 9], id: \.self) { fret in
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 5, height: 5)
                            .position(x: 8 + (CGFloat(fret) - 0.5) * step, y: geo.size.height / 2)
                    }
                    // Casa 12 (Duplo ponto)
                    VStack(spacing: 8) {
                        Circle().fill(Color.white.opacity(0.25)).frame(width: 4, height: 4)
                        Circle().fill(Color.white.opacity(0.25)).frame(width: 4, height: 4)
                    }
                    .position(x: 8 + 11.5 * step, y: geo.size.height / 2)
                }
                
                // As 6 cordas de violão/guitarra esticadas
                VStack(spacing: 9) {
                    ForEach(1...6, id: \.self) { strIndex in
                        Rectangle()
                            .fill(LinearGradient(colors: [Color.gray, Color.white.opacity(0.8), Color.gray], startPoint: .top, endPoint: .bottom))
                            .frame(height: CGFloat(strIndex) * 0.45 + 0.6)
                            .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    }
                }
                
                // Ponto luminoso indicando o dedo ativo na escala
                if let note = activeNote {
                    GeometryReader { geo in
                        let step = (geo.size.width - 16) / 15.0
                        let stringHeight: CGFloat = 9.4
                        let yPos = CGFloat(note.string - 1) * stringHeight + (geo.size.height / 2 - 24)
                        let xPos = 8 + (CGFloat(note.fret) - 0.5) * step
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 14, height: 14)
                            .shadow(color: .red, radius: 6)
                            .position(x: note.fret == 0 ? 8 : xPos, y: yPos)
                            .transition(.scale)
                    }
                }
            }
            .frame(height: 70)
            .padding(.horizontal, 16)
        }
    }
}
