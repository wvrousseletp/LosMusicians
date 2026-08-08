import SwiftUI

struct TechniqueModule: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let bpm: Int
    let difficulty: String
    let gradientColors: [Color]
    let alphaTex: String
    let instrumentType: InstrumentType
}

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var offlineManager = OfflineTabManager.shared
    
    @State private var selectedSongForPlayer: Song? = nil
    
    // Estado do buscador de músicas com IA
    @State private var searchQuery: String = ""
    @State private var selectedInstrument: String = "Guitarra"
    @State private var isSearching: Bool = false
    @State private var aiSteps: [AISongStep] = []
    @State private var searchedSongTitle: String = ""
    @State private var errorMessage: String? = nil
    
    let instruments = ["Guitarra", "Violão", "Baixo", "Teclado"]
    
    // Módulos de Técnica Interativos
    let techniqueModules: [TechniqueModule] = [
        TechniqueModule(
            title: "Palhetada Alternada",
            subtitle: "Velocidade & Sincronia",
            icon: "bolt.fill",
            bpm: 120,
            difficulty: "Intermediário",
            gradientColors: [Color.cyan, Color.blue],
            alphaTex: "\\tempo 120 . \\instrument 29 0.6 2.6 3.6 2.6 | 0.6 2.6 3.6 2.6 | 0.5 2.5 3.5 2.5 | 0.4 2.4 3.4 2.4 |",
            instrumentType: .leadGuitar
        ),
        TechniqueModule(
            title: "Bends & Vibratos",
            subtitle: "Expressão & Sustentação",
            icon: "waveform.path.ecg",
            bpm: 85,
            difficulty: "Avançado",
            gradientColors: [Color.orange, Color.red],
            alphaTex: "\\tempo 85 . \\instrument 30 7.3{b(0 4 0)} 9.3{v} 7.3 | 8.2{b(0 4 0)} 10.2{v} | 7.1{b(0 4 0)} 10.1{v} | 12.1{v} 10.1 8.1 7.1 |",
            instrumentType: .leadGuitar
        ),
        TechniqueModule(
            title: "Legato & Hammer-ons",
            subtitle: "Fluidez & Articulação",
            icon: "sparkles",
            bpm: 105,
            difficulty: "Médio",
            gradientColors: [Color.purple, Color.pink],
            alphaTex: "\\tempo 105 . \\instrument 29 5.3 7.3{h} 8.3{h} 7.3{p} | 5.2 7.2{h} 8.2{h} 7.2{p} | 5.1 7.1{h} 8.1{h} 7.1{p} | 8.1 7.1 5.1 8.2 |",
            instrumentType: .leadGuitar
        ),
        TechniqueModule(
            title: "Fingerstyle & Arpejos",
            subtitle: "Independência de Dedos",
            icon: "hand.raised.fill",
            bpm: 90,
            difficulty: "Fácil",
            gradientColors: [Color.green, Color.teal],
            alphaTex: "\\tempo 90 . \\instrument 25 0.6 0.3 0.2 0.1 | 2.5 0.3 0.2 0.1 | 3.5 0.3 0.2 0.1 | 0.6 0.3 0.2 0.1 |",
            instrumentType: .leadGuitar
        )
    ]
    
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
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        levelCardSection
                        
                        // 1. Continue de Onde Parou (Histórico Recente)
                        if let recent = offlineManager.recentSong {
                            recentTrainingSection(song: recent)
                        }
                        
                        // 2. Desafio Riff do Dia
                        dailyChallengeSection
                        
                        // 3. Treino por Foco de Técnica
                        techniqueFocusSection
                        
                        // 4. Músicas Salvas Offline (Acesso Rápido)
                        if !offlineManager.savedSongs.isEmpty {
                            offlineQuickAccessSection
                        }
                        
                        // 5. Aprenda com IA
                        aiSongSearchSection
                    }
                    .padding(.vertical)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedSongForPlayer) { song in
                TabPlayerView(song: song)
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Olá, \(user.name)! 👋")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("Pronto para evoluir na música hoje?")
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
    
    // MARK: - Card de Nível e XP
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
                        
                        Text("Shredder Pro")
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                    }
                    
                    Text("\(user.xp) XP Total")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: "guitars.fill")
                    .font(.system(size: 38))
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
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(user.levelProgressFraction), height: 8)
                    }
                }
                .frame(height: 8)
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
        .padding(18)
        .background(Color.white.opacity(0.06))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // MARK: - 1. Continue de Onde Parou
    private func recentTrainingSection(song: Song) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Continue de Onde Parou")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Spacer()
                Text("Última Sessão")
                    .font(.caption.bold())
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal)
            
            Button(action: {
                selectedSongForPlayer = song
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(LinearGradient(colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 58, height: 58)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                            )
                        
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.cyan)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            HStack(spacing: 3) {
                                Image(systemName: "metronome.fill")
                                Text("\(song.bpm) BPM")
                            }
                            .font(.caption2.bold())
                            .foregroundColor(.cyan)
                            
                            Text("•")
                                .foregroundColor(.gray)
                            
                            Text(song.difficulty)
                                .font(.caption2.bold())
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("Retomar")
                            .font(.subheadline.bold())
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.cyan)
                    .cornerRadius(12)
                    .shadow(color: Color.cyan.opacity(0.3), radius: 6)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 0.10, green: 0.12, blue: 0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 2. Desafio Riff do Dia
    private var dailyChallengeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Desafio Riff do Dia")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                Spacer()
                Text("+50 XP")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            Button(action: {
                // Abre o Riff do Dia (Sweet Child O' Mine)
                if let challengeSong = Song.sampleSongs.first {
                    selectedSongForPlayer = challengeSong
                }
            }) {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.4), Color.orange.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Sweet Child O' Mine — Intro Solo")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                Text("Guns N' Roses • Guitarra Solo")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "trophy.fill")
                                .font(.title)
                                .foregroundColor(.yellow)
                        }
                        
                        HStack {
                            HStack(spacing: 12) {
                                Label("128 BPM", systemImage: "metronome")
                                Label("8 Compassos", systemImage: "music.note")
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                Text("Tocar Desafio")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.yellow)
                            .cornerRadius(12)
                            .shadow(color: Color.yellow.opacity(0.4), radius: 6)
                        }
                    }
                    .padding(16)
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(LinearGradient(colors: [.purple, .orange], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                )
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 3. Treino por Foco de Técnica
    private var techniqueFocusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Treino por Foco de Técnica")
                .font(.title3.bold())
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(techniqueModules) { module in
                        Button(action: {
                            playTechniqueModule(module)
                        }) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(colors: module.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: module.icon)
                                            .foregroundColor(.white)
                                            .font(.headline)
                                    }
                                    Spacer()
                                    Text(module.difficulty)
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.white.opacity(0.1))
                                        .foregroundColor(.white.opacity(0.8))
                                        .cornerRadius(6)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(module.title)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(module.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                                
                                HStack {
                                    Text("\(module.bpm) BPM")
                                        .font(.caption2.bold())
                                        .foregroundColor(.cyan)
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .padding(14)
                            .frame(width: 175, height: 140)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(LinearGradient(colors: module.gradientColors.map { $0.opacity(0.6) }, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 4. Músicas Salvas Offline (Acesso Rápido)
    private var offlineQuickAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                    Text("Salvos Offline")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                Spacer()
                Text("\(offlineManager.savedSongs.count) Músicas")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(offlineManager.savedSongs) { song in
                        Button(action: {
                            selectedSongForPlayer = song
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "guitars.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                                
                                Text(song.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text(song.artist)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                
                                HStack {
                                    Text("\(song.bpm) BPM")
                                        .font(.caption2.bold())
                                        .foregroundColor(.green)
                                    Spacer()
                                    Image(systemName: "play.circle.fill")
                                        .foregroundColor(.white)
                                        .font(.title3)
                                }
                            }
                            .padding(12)
                            .frame(width: 155, height: 110)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 5. Aprenda Qualquer Música com IA
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
    
    // MARK: - Ações
    private func playTechniqueModule(_ module: TechniqueModule) {
        let dynSong = Song(
            id: "technique-\(module.title.lowercased().replacingOccurrences(of: " ", with: "-"))",
            title: "Treino: \(module.title)",
            artist: module.subtitle,
            difficulty: module.difficulty,
            bpm: module.bpm,
            tracks: [
                InstrumentTrack(
                    id: "track-tech-1",
                    name: module.title,
                    instrument: module.instrumentType
                )
            ],
            isPublic: true,
            authorName: "Los Musicians Academy",
            tabDataJson: module.alphaTex
        )
        selectedSongForPlayer = dynSong
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
        let instEnum: InstrumentType
        switch selectedInstrument {
        case "Violão": instEnum = .leadGuitar
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
