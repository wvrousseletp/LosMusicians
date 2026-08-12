import SwiftUI

struct AILessonPlanView: View {
    let songResult: SongSearchResult
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isLoading: Bool = true
    @State private var aiTips: [String] = []
    @State private var showPlayer: Bool = false
    @State private var readySong: Song? = nil
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 24) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    
                    Text("Analisando '\(songResult.title)' com IA...")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Baixando tablatura real e gerando plano de estudos...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .onAppear {
                    simulateAILoading()
                }
            } else {
                VStack(spacing: 24) {
                    // Cabeçalho
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 32))
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("Plano de Aula")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            Text("\(songResult.title) - \(songResult.artist)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 40)
                    
                    // Dicas da IA
                    VStack(spacing: 16) {
                        ForEach(0..<aiTips.count, id: \.self) { index in
                            HStack(alignment: .top, spacing: 16) {
                                Circle()
                                    .fill(Color.purple.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.purple)
                                    )
                                
                                Text(aiTips[index])
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: {
                        showPlayer = true
                    }) {
                        Text("IR PARA A TABLATURA REAL")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(16)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let song = readySong {
                TabPlayerView(song: song, songId: songResult.songId)
            }
        }
    }
    
    private func simulateAILoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // Gera as dicas
            self.aiTips = [
                "Esta música contém palhetada alternada rápida. Aqueça seu pulso direito antes de começar.",
                "Foque primeiro em tocar os riffs principais a 50% da velocidade original usando o Speed Trainer.",
                "Cuidado com a precisão dos bends no solo; use seu dedo anelar apoiado pelos outros para ter mais força."
            ]
            
            // Cria o "Song" para o player
            let alphaTex = TabSearchService.shared.fetchMockAlphaTex(for: songResult)
            
            self.readySong = Song(
                id: String(songResult.songId),
                title: songResult.title,
                artist: songResult.artist,
                coverUrl: nil,
                difficulty: "Médio", // Seria definido pela IA
                bpm: 120,
                tracks: [
                    InstrumentTrack(id: "t_main", name: "Guitarra Principal", instrument: .leadGuitar, tabDataJson: alphaTex)
                ],
                isPublic: true,
                authorName: "IA / Songsterr"
            )
            
            withAnimation {
                self.isLoading = false
            }
        }
    }
}
