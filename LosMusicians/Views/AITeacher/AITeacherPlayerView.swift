import SwiftUI

struct AITeacherPlayerView: View {
    let instrument: String
    let technique: String
    let timeAvailable: Int
    let isChallengeMode: Bool
    
    @State private var isPlaying = false
    @State private var tempo = 120
    @State private var currentTrack = "1"
    
    @State private var showingFeedback = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(red: 15/255, green: 15/255, blue: 19/255).edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Professor IA: \(technique)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("\(instrument) • \(isChallengeMode ? "Desafio" : "Aquecimento")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    Button(action: {
                        showingFeedback = true
                    }) {
                        Text("Concluir")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                }
                .padding()
                
                // Tablature Area
                AlphaTabWebView(
                    isPlaying: $isPlaying,
                    tempo: $tempo,
                    currentInstrumentTrack: $currentTrack
                )
                .frame(maxHeight: .infinity)
                .padding(.horizontal)
                
                // Controls
                VStack(spacing: 20) {
                    // Playback Controls
                    HStack(spacing: 40) {
                        Button(action: { tempo = max(60, tempo - 10) }) {
                            Image(systemName: "tortoise.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: { isPlaying.toggle() }) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.cyan)
                        }
                        
                        Button(action: { tempo = min(240, tempo + 10) }) {
                            Image(systemName: "hare.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.bottom, 30)
                .padding(.top, 10)
            }
        }
        .sheet(isPresented: $showingFeedback) {
            DDAFeedbackView(technique: technique)
        }
    }
}

struct DDAFeedbackView: View {
    let technique: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Como foi o treino?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Seu feedback ajuda a IA a calibrar a dificuldade do próximo exercício de \(technique).")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 15) {
                    FeedbackButton(title: "Muito Difícil 🥵", subtitle: "A IA vai diminuir a velocidade e a densidade de notas.", color: .red) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    FeedbackButton(title: "Perfeito! 😎", subtitle: "Ganhe +50 XP. A IA manterá esse nível de desafio.", color: .green) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    FeedbackButton(title: "Muito Fácil 🥱", subtitle: "A IA vai introduzir padrões mais complexos na próxima.", color: .blue) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationBarItems(trailing: Button("Fechar") {
                presentationMode.wrappedValue.dismiss()
            })
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
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(subtitle)
                        .font(.caption)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .foregroundColor(.white)
            .background(color.opacity(0.8))
            .cornerRadius(15)
        }
    }
}
