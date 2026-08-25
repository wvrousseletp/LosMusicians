import SwiftUI

struct AILessonPlanView: View {
    let song: Song
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isLoading: Bool = true
    @State private var aiTips: [String] = []
    @State private var showPlayer: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()
            
            if isLoading {
                loadingView
            } else {
                contentView
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            TabPlayerView(song: song)
        }
        .onAppear {
            loadAITips()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
            
            VStack(spacing: 8) {
                Text("Analisando \"\(song.title)\" com IA...")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Gerando plano de estudos personalizado...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        VStack(spacing: 0) {
            // Header com dismiss
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Cabeçalho
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 56, height: 56)
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Plano de Aula IA")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            Text("\(song.title) · \(song.artist)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        Spacer()
                        
                        // Badge dificuldade
                        Text(song.difficulty)
                            .font(.caption.bold())
                            .foregroundColor(difficultyColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(difficultyColor.opacity(0.15))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    // Infos da música
                    HStack(spacing: 12) {
                        infoChip(icon: "metronome.fill", label: "\(song.bpm) BPM", color: .cyan)
                        infoChip(icon: "music.note.list", label: "\(song.tracks.count) faixa\(song.tracks.count > 1 ? "s" : "")", color: .purple)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.horizontal, 20)
                    
                    // Dicas da IA
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dicas do Professor IA")
                            .font(.headline.bold())
                            .foregroundColor(.purple)
                            .padding(.horizontal, 20)
                        
                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.08))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
                        
                        ForEach(Array(aiTips.enumerated()), id: \.offset) { index, tip in
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.purple.opacity(0.2))
                                        .frame(width: 34, height: 34)
                                    Text("\(index + 1)")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.purple)
                                }
                                
                                Text(tip)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(14)
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            
            // Botão fixo no fundo
            Button(action: { showPlayer = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "guitars.fill")
                        .font(.headline)
                    Text("IR PARA A TABLATURA REAL")
                        .font(.headline.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .shadow(color: .purple.opacity(0.4), radius: 10, y: 4)
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 34)
        }
    }
    
    // MARK: - Helpers
    
    private var difficultyColor: Color {
        switch song.difficulty {
        case "Insano": return .red
        case "Difícil": return .orange
        case "Médio": return .yellow
        default: return .green
        }
    }
    
    private func infoChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.caption2)
            Text(label).font(.caption.bold())
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .cornerRadius(8)
    }
    
    private func loadAITips() {
        Task {
            do {
                let tips = try await GeminiService.shared.generateLessonTips(
                    songTitle: song.title,
                    artist: song.artist,
                    difficulty: song.difficulty,
                    bpm: song.bpm
                )
                await MainActor.run {
                    self.aiTips = tips
                    withAnimation { self.isLoading = false }
                }
            } catch {
                await MainActor.run {
                    // Fallback gracioso: mostra dicas padrão sem travar o fluxo
                    self.aiTips = GeminiService.shared.fallbackTipsPublic(for: song.difficulty)
                    self.errorMessage = "IA offline. Mostrando dicas padrão."
                    withAnimation { self.isLoading = false }
                }
            }
        }
    }
}
