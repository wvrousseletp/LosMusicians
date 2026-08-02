import SwiftUI
import SwiftData

struct AITeacherPlayerView: View {
    let instrument: String
    let technique: String
    let timeAvailable: Int
    let isChallengeMode: Bool
    let alphaTex: String
    var exercise: ExerciseModel? = nil
    
    @State private var isPlaying = false
    @State private var tempo = 100
    @State private var score = 0
    @State private var maxScore = 0
    
    @State private var showingFeedback = false
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var pitchDetector = PitchDetector()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ZStack {
            // Fundo escuro premium
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
                // Header
                HStack(spacing: 12) {
                    Button(action: {
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
                        Text("Professor IA: \(technique)")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("\(instrument) • \(isChallengeMode ? "Desafio" : "Aquecimento")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    Button(action: {
                        saveExercise()
                        showingFeedback = true
                    }) {
                        Text("Concluir")
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(LinearGradient(colors: [.green, Color(red: 0.1, green: 0.8, blue: 0.4)], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(color: .green.opacity(0.4), radius: 6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                
                // Tablatura Interativa Nativa em Tempo Real
                InteractiveTablatureView(
                    alphaTex: alphaTex,
                    isPlaying: $isPlaying,
                    tempo: $tempo
                )
                .padding(.horizontal, 16)
                
                // Indicador de Microfone / Nota Detectada & Placar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: pitchDetector.currentNote != "--" ? "mic.fill" : "mic.slash.fill")
                                .foregroundColor(pitchDetector.currentNote != "--" ? .green : .gray)
                            
                            Text("Nota Detectada:")
                                .foregroundColor(.gray)
                                .font(.system(size: 13, weight: .medium))
                            
                            Text(pitchDetector.currentNote)
                                .font(.system(size: 18, weight: .black, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                        
                        Text(String(format: "Frequência: %.1f Hz", pitchDetector.currentFrequency))
                            .foregroundColor(.gray)
                            .font(.caption2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Pontuação")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text("\(score) / \(maxScore)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                
                Spacer(minLength: 4)
                
                // Painel de Controle de Playback
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Controle de BPM com - e +
                        HStack(spacing: 8) {
                            Button(action: { tempo = max(40, tempo - 5) }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            }
                            
                            Text("\(tempo) BPM")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(.cyan)
                            
                            Button(action: { tempo = min(260, tempo + 5) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    // Botão Play/Pause Master
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        isPlaying.toggle()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text(isPlaying ? "PAUSAR TREINO" : "TOCAR EXERCÍCIO")
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
        .onAppear {
            pitchDetector.start()
            if let exercise = exercise {
                self.score = exercise.score
                self.maxScore = exercise.maxScore
            }
        }
        .onDisappear {
            pitchDetector.stop()
            isPlaying = false
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AlphaTabPlayedNote"))) { notification in
            guard isPlaying, let userInfo = notification.userInfo, let expectedMidi = userInfo["midi"] as? Int else { return }
            
            maxScore += 1
            
            let detectedMidi = pitchDetector.currentMidiNote
            if abs(detectedMidi - expectedMidi) <= 1 {
                score += 1
            }
        }
        .sheet(isPresented: $showingFeedback) {
            DDAFeedbackView(technique: technique, score: score, maxScore: maxScore)
        }
    }
    
    private func saveExercise() {
        if let exercise = exercise {
            exercise.score = max(exercise.score, score)
            exercise.maxScore = max(exercise.maxScore, maxScore)
            try? modelContext.save()
        } else {
            let newExercise = ExerciseModel(
                title: "\(technique) - \(isChallengeMode ? "Desafio" : "Treino")",
                instrument: instrument,
                technique: technique,
                alphaTex: alphaTex,
                score: score,
                maxScore: maxScore,
                dateCreated: Date()
            )
            modelContext.insert(newExercise)
            try? modelContext.save()
        }
    }
}

struct DDAFeedbackView: View {
    let technique: String
    let score: Int
    let maxScore: Int
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Como foi o treino?")
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)
                
                Text("Você acertou \(score) de \(maxScore) notas!")
                    .font(.title2.weight(.bold))
                    .foregroundColor(score > maxScore / 2 ? .green : .orange)
                
                Text("Seu feedback ajuda a IA a calibrar a dificuldade do próximo exercício de \(technique).")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    FeedbackButton(title: "Muito Difícil 🥵", subtitle: "A IA vai diminuir a velocidade e a densidade.", color: .red) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    FeedbackButton(title: "Perfeito! 😎", subtitle: "Ganhe +50 XP. A IA manterá esse nível de desafio.", color: .green) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    FeedbackButton(title: "Muito Fácil 🥱", subtitle: "A IA vai introduzir padrões mais complexos.", color: .blue) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 30)
            .background(Color(red: 0.08, green: 0.08, blue: 0.12).ignoresSafeArea())
            .navigationBarItems(trailing: Button("Fechar") {
                presentationMode.wrappedValue.dismiss()
            }.foregroundColor(.cyan))
        }
    }
}

struct FeedbackButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.bold))
                    Text(subtitle)
                        .font(.caption)
                        .opacity(0.8)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(14)
            .foregroundColor(.white)
            .background(color.opacity(0.8))
            .cornerRadius(14)
        }
    }
}
