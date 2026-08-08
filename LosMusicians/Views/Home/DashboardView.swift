import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedSongForPlayer: Song? = nil
    
    // Estado do buscador de músicas com IA
    @State private var searchQuery: String = ""
    @State private var selectedInstrument: String = "Guitarra"
    @State private var isSearching: Bool = false
    @State private var aiSteps: [AISongStep] = []
    @State private var searchedSongTitle: String = ""
    @State private var errorMessage: String? = nil
    
    let instruments = ["Guitarra", "Violão", "Baixo", "Teclado"]
    
    private func iconForInstrument(_ inst: String) -> String {
        switch inst {
        case "Guitarra": return "guitars.fill"
        case "Violão": return "music.quarternote.3"
        case "Baixo": return "waveform.path"
        default: return "piano"
        }
    }
    
    var user: AppUser {
        authManager.currentUser ?? AppUser(id: "guest", name: "Músico", email: "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        levelCardSection
                        aiSongSearchSection
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedSongForPlayer) { song in
                TabPlayerView(song: song)
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Olá, \(user.name)! 👋")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("Pronto para o treino de hoje?")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.headline)
                Text("\(user.streakDays)")
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.orange, lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }
    
    private var levelCardSection: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Nível \(user.level)")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.3))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                        
                        Text("Shredder")
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                    }
                    
                    Text("\(user.xp) XP Total")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: "guitars.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .purple], startPoint: .top, endPoint: .bottom)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Progresso para o Nível \(user.level + 1)")
                        .font(.footnote.bold())
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(user.xpInCurrentLevel) / \(user.xpNeededForNextLevel) XP")
                        .font(.footnote.bold())
                        .foregroundColor(.purple)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 10)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(user.levelProgressFraction), height: 10)
                    }
                }
                .frame(height: 10)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Meta Diária: \(user.todayPracticeMinutes) / \(user.dailyGoalMinutes) min")
                        .font(.footnote.bold())
                        .foregroundColor(.gray)
                    Spacer()
                    let percentage = Int(min(1.0, Double(user.todayPracticeMinutes) / Double(max(1, user.dailyGoalMinutes))) * 100)
                    Text("\(percentage)%")
                        .font(.footnote.bold())
                        .foregroundColor(.cyan)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)
                        
                        let fillWidth = geo.size.width * CGFloat(min(1.0, Double(user.todayPracticeMinutes) / Double(max(1, user.dailyGoalMinutes))))
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                            .frame(width: fillWidth, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.06))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private var aiSongSearchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aprenda Qualquer Música com IA")
                .font(.title3.bold())
                .foregroundColor(.white)
                .padding(.horizontal)
            
            VStack(spacing: 14) {
                // Seletor de instrumento horizontal
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(instruments, id: \.self) { inst in
                            Button(action: {
                                selectedInstrument = inst
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: iconForInstrument(inst))
                                    Text(inst)
                                        .font(.subheadline.bold())
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedInstrument == inst ? Color.cyan.opacity(0.2) : Color.white.opacity(0.06))
                                .foregroundColor(selectedInstrument == inst ? .cyan : .gray)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedInstrument == inst ? Color.cyan.opacity(0.6) : Color.clear, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Barra de pesquisa
                HStack(spacing: 10) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Ex: Back in Black, Sweet Child O' Mine", text: $searchQuery)
                            .foregroundColor(.white)
                            .submitLabel(.search)
                            .onSubmit {
                                searchAndSplitSong()
                            }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                    
                    Button(action: searchAndSplitSong) {
                        if isSearching {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .frame(width: 44, height: 44)
                                .background(Color.cyan)
                                .cornerRadius(12)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.title3.bold())
                                .foregroundColor(.black)
                                .frame(width: 44, height: 44)
                                .background(Color.cyan)
                                .cornerRadius(12)
                                .shadow(color: .cyan.opacity(0.4), radius: 6)
                        }
                    }
                    .disabled(isSearching || searchQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 20)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
                
                // Resultados dos passos da IA
                if !aiSteps.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(searchedSongTitle)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Exercício passo a passo para \(selectedInstrument)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        
                        ForEach(Array(aiSteps.enumerated()), id: \.offset) { index, step in
                            Button(action: {
                                playAIStep(step)
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.cyan.opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        Text("\(index + 1)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.cyan)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(step.stepName)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        Text(step.description)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "play.fill")
                                        .foregroundColor(.cyan)
                                        .font(.footnote)
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.03))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }
    
    private func searchAndSplitSong() {
        let cleanedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedQuery.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        aiSteps = []
        
        Task {
            do {
                let steps = try await GeminiService.shared.generateSongSteps(songTitle: cleanedQuery, instrument: selectedInstrument)
                await MainActor.run {
                    self.aiSteps = steps
                    self.searchedSongTitle = cleanedQuery
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erro ao buscar aula: \(error.localizedDescription)"
                    self.isSearching = false
                }
            }
        }
    }
    
    private func playAIStep(_ step: AISongStep) {
        // Converte o passo de IA em uma estrutura de Song aceita pelo TabPlayerView
        let instEnum: InstrumentType
        switch selectedInstrument {
        case "Violão": instEnum = .leadGuitar // violao mapeia para leadGuitar de afinação normal
        case "Baixo": instEnum = .bass
        case "Teclado": instEnum = .keys
        default: instEnum = .leadGuitar
        }
        
        let dynamicSong = Song(
            id: "ai-step-\(UUID().uuidString)",
            title: step.stepName,
            artist: searchedSongTitle,
            difficulty: "Médio",
            bpm: step.bpm,
            tracks: [
                InstrumentTrack(
                    id: "t-ai",
                    name: "\(selectedInstrument) - Aula IA",
                    instrument: instEnum
                )
            ],
            isPublic: false,
            authorName: "IA Professor",
            tabDataJson: step.alphaTex
        )
        
        selectedSongForPlayer = dynamicSong
    }
}
