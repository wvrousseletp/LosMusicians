import SwiftUI

// MARK: - Modelo de Nota da Tablatura
struct TabNoteItem: Identifiable, Equatable {
    let id = UUID()
    let string: Int      // 1 (mais aguda) a 6 (mais grave)
    let fret: Int        // 0 a 24
    let durationBeats: Double // 0.5 = colcheia (8th), 1.0 = semínima (4th)
    let measureIndex: Int
    let noteIndex: Int
    
    var midiValue: Int {
        let openMidiByString: [Int: Int] = [
            6: 40, // E2
            5: 45, // A2
            4: 50, // D3
            3: 55, // G3
            2: 59, // B3
            1: 64  // E4
        ]
        return (openMidiByString[string] ?? 40) + fret
    }
    
    var noteName: String {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let noteIndex = midiValue % 12
        let octave = (midiValue / 12) - 1
        return "\(noteNames[noteIndex])\(octave)"
    }
}

// MARK: - Parser de Tablatura (AlphaTex e formato universal)
struct TabParser {
    static func parse(alphaTex: String?) -> [TabNoteItem] {
        var rawText = (alphaTex ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if rawText.isEmpty {
            rawText = ":8 5.6 7.6 8.6 7.6 5.5 7.5 8.5 7.5 | 5.4 7.4 8.4 7.4 5.3 7.3 8.3 7.3 | 5.2 7.2 8.2 7.2 5.1 7.1 8.1 7.1 | 8.1 7.1 5.1 7.1 8.2 7.2 5.2 7.2"
        }
        
        // Normaliza quebras de linha literais (geradas como texto pela IA no JSON)
        rawText = rawText
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\r", with: "")
        
        // Remove linhas de metadados (\title, \tempo, .)
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
        var currentDuration: Double = 0.5 // Default colcheia
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
                    currentDuration = 4.0 / durNum // :4 -> 1.0, :8 -> 0.5, :16 -> 0.25
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
                // Se for só número, assume corda 6
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
            // Fallback com escala penta
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
        
        return notes
    }
}

// MARK: - View Principal da Tablatura Interativa
struct InteractiveTablatureView: View {
    let alphaTex: String?
    @Binding var isPlaying: Bool
    @Binding var tempo: Int
    var instrument: String = "Guitarra"
    
    @Binding var isMetronomeActive: Bool
    @Binding var isSpeedTrainerActive: Bool
    
    var onNotePlayed: ((Int) -> Void)? = nil
    
    @State private var notes: [TabNoteItem] = []
    @State private var currentActiveIndex: Int = -1
    @State private var playbackTimer: Timer? = nil
    @State private var showFretboard: Bool = true
    @State private var tickCounter: Int = 0
    
    private let stringNames = ["e", "B", "G", "D", "A", "E"]
    
    var body: some View {
        VStack(spacing: 12) {
            // Mini Braço de Guitarra Dinâmico (Fretboard Visualizer)
            if showFretboard {
                GuitarFretboardVisualizer(activeNote: currentActiveIndex >= 0 && currentActiveIndex < notes.count ? notes[currentActiveIndex] : nil)
                    .transition(.opacity.combined(with: .scale))
            }
            
            // Área de Partitura / Tablatura Estilizada
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.07, green: 0.07, blue: 0.11))
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
                    // Header da Tablatura
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isPlaying ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text(isPlaying ? "EM REPRODUÇÃO" : "MODO DE PRÁTICA")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(isPlaying ? .green : .orange)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        // Alternador de visualizador de braço
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
                    
                    // Grade da Tablatura com ScrollView Horizontal
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                // Coluna das Cordas (Fixa)
                                VStack(spacing: 18) {
                                    ForEach(0..<6, id: \.self) { idx in
                                        Text(stringNames[idx])
                                            .font(.system(size: 13, weight: .black, design: .monospaced))
                                            .foregroundColor(.cyan.opacity(0.8))
                                            .frame(width: 24, height: 20)
                                    }
                                }
                                .padding(.leading, 12)
                                .padding(.trailing, 8)
                                
                                Divider()
                                    .frame(width: 2, height: 160)
                                    .background(Color.white.opacity(0.2))
                                
                                // Notas e Linhas da Tablatura
                                ZStack(alignment: .leading) {
                                    // As 6 Linhas da Guitarra
                                    VStack(spacing: 20) {
                                        ForEach(1...6, id: \.self) { stringIndex in
                                            Rectangle()
                                                .fill(Color.white.opacity(stringIndex == 1 || stringIndex == 6 ? 0.25 : 0.15))
                                                .frame(height: 1.5)
                                        }
                                    }
                                    .frame(width: CGFloat(max(notes.count * 48 + 80, 320)))
                                    
                                    // Notas renderizadas
                                    HStack(spacing: 0) {
                                        ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                                            TabNoteNodeView(
                                                note: note,
                                                isActive: currentActiveIndex == index,
                                                onTap: {
                                                    playSingleNote(index: index)
                                                }
                                            )
                                            .id(index)
                                            .frame(width: 48)
                                        }
                                    }
                                    .padding(.leading, 16)
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.trailing, 40)
                        }
                        .onChange(of: currentActiveIndex) { newIndex in
                            if newIndex >= 0 {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    proxy.scrollTo(newIndex, anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
            .frame(minHeight: 220, maxHeight: 260)
        }
        .onAppear {
            self.notes = TabParser.parse(alphaTex: alphaTex)
        }
        .onChange(of: alphaTex) { newTex in
            self.notes = TabParser.parse(alphaTex: newTex)
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                startPlayback()
            } else {
                stopPlayback()
            }
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    private func playSingleNote(index: Int) {
        guard index >= 0 && index < notes.count else { return }
        currentActiveIndex = index
        let note = notes[index]
        GuitarSynthEngine.shared.playFret(string: note.string, fret: note.fret, instrument: instrument)
        
        NotificationCenter.default.post(
            name: NSNotification.Name("AlphaTabPlayedNote"),
            object: nil,
            userInfo: ["midi": note.midiValue]
        )
        onNotePlayed?(note.midiValue)
    }
    
    private func startPlayback() {
        playbackTimer?.invalidate()
        tickCounter = 0
        if currentActiveIndex < 0 || currentActiveIndex >= notes.count - 1 {
            currentActiveIndex = -1
        }
        
        // Intervalo de batidas baseado no BPM e colcheias (60.0 / BPM * durationBeats)
        let beatInterval = 60.0 / Double(max(30, tempo))
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: beatInterval * 0.5, repeats: true) { _ in
            DispatchQueue.main.async {
                // Toca metrônomo
                if self.isMetronomeActive {
                    if self.tickCounter % 2 == 0 {
                        let isStrongBeat = (self.tickCounter / 2) % 4 == 0
                        GuitarSynthEngine.shared.playMetronomeTick(isStrong: isStrongBeat)
                    }
                }
                self.tickCounter += 1
                
                if self.currentActiveIndex + 1 < self.notes.count {
                    self.currentActiveIndex += 1
                    let note = self.notes[self.currentActiveIndex]
                    
                    // Emite som nativo com harmônicos ricos específicos do instrumento
                    GuitarSynthEngine.shared.playFret(string: note.string, fret: note.fret, instrument: self.instrument)
                    
                    // Notifica mic e pontuação
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AlphaTabPlayedNote"),
                        object: nil,
                        userInfo: ["midi": note.midiValue]
                    )
                    self.onNotePlayed?(note.midiValue)
                } else {
                    // Fim da tablatura -> loop contínuo
                    if self.isSpeedTrainerActive {
                        // Acelera +5 BPM para treino incremental
                        self.tempo = min(280, self.tempo + 5)
                        self.startPlayback()
                        return
                    }
                    
                    self.currentActiveIndex = 0
                    self.tickCounter = 0
                    let note = self.notes[0]
                    GuitarSynthEngine.shared.playFret(string: note.string, fret: note.fret, instrument: self.instrument)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AlphaTabPlayedNote"),
                        object: nil,
                        userInfo: ["midi": note.midiValue]
                    )
                    self.onNotePlayed?(note.midiValue)
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

// MARK: - Nó da Nota Individual
struct TabNoteNodeView: View {
    let note: TabNoteItem
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Espaçamento vertical para posicionar a nota na corda correta (1 a 6)
                // Altura total das 6 linhas = 120px (espaçamento de 20px entre cordas)
                ZStack {
                    // Posição calculada por corda
                    let yOffset = CGFloat(note.string - 1) * 21.5 - 54
                    
                    // Traste / Fret Badge
                    ZStack {
                        Circle()
                            .fill(
                                isActive ?
                                LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [Color(red: 0.15, green: 0.15, blue: 0.22), Color(red: 0.1, green: 0.1, blue: 0.15)], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: isActive ? 28 : 22, height: isActive ? 28 : 22)
                            .shadow(color: isActive ? Color.cyan.opacity(0.8) : Color.black.opacity(0.5), radius: isActive ? 8 : 2)
                        
                        Text("\(note.fret)")
                            .font(.system(size: isActive ? 13 : 11, weight: .black, design: .rounded))
                            .foregroundColor(isActive ? .white : .cyan)
                    }
                    .offset(y: yOffset)
                    .scaleEffect(isActive ? 1.15 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isActive)
                }
                .frame(height: 140)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Braço da Guitarra Visualizador (Fretboard)
struct GuitarFretboardVisualizer: View {
    let activeNote: TabNoteItem?
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("🎸 BRAÇO DA GUITARRA")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                if let note = activeNote {
                    Text("Nota: \(note.noteName) (Corda \(note.string), Casa \(note.fret))")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
            }
            .padding(.horizontal, 16)
            
            ZStack(alignment: .leading) {
                // Madeira da escala da guitarra
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.18, green: 0.12, blue: 0.09), Color(red: 0.12, green: 0.08, blue: 0.06)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                // Trastes verticais (Casas 0 a 12)
                HStack(spacing: 0) {
                    ForEach(0...12, id: \.self) { fret in
                        VStack {
                            Spacer()
                            // Marcadores de bolinha (Casas 3, 5, 7, 9, 12)
                            if [3, 5, 7, 9].contains(fret) {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 4, height: 4)
                            } else if fret == 12 {
                                HStack(spacing: 2) {
                                    Circle().fill(Color.white.opacity(0.2)).frame(width: 3, height: 3)
                                    Circle().fill(Color.white.opacity(0.2)).frame(width: 3, height: 3)
                                }
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .overlay(
                            Rectangle()
                                .fill(fret == 0 ? Color.gray : Color.white.opacity(0.3))
                                .frame(width: fret == 0 ? 3 : 1),
                            alignment: .trailing
                        )
                    }
                }
                
                // 6 Cordas horizontais
                VStack(spacing: 8.5) {
                    ForEach(1...6, id: \.self) { s in
                        Rectangle()
                            .fill(Color(white: 0.7 - Double(s) * 0.05))
                            .frame(height: Double(s) * 0.35 + 0.5)
                    }
                }
                .padding(.horizontal, 4)
                
                // Dedo / Marcador de Nota Ativa
                if let note = activeNote, note.fret <= 12 {
                    GeometryReader { geo in
                        let fretWidth = geo.size.width / 13.0
                        let xPos = note.fret == 0 ? fretWidth * 0.3 : (CGFloat(note.fret) - 0.5) * fretWidth
                        let yPos = CGFloat(note.string - 1) * 9.5 + 8.5
                        
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 14, height: 14)
                            .shadow(color: .cyan, radius: 6)
                            .overlay(
                                Text("\(note.fret)")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.black)
                            )
                            .position(x: xPos, y: yPos)
                            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: note)
                    }
                }
            }
            .frame(height: 64)
            .padding(.horizontal, 16)
        }
    }
}
