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
