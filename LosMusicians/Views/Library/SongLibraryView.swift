import SwiftUI

struct SongLibraryView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var offlineManager = OfflineTabManager.shared
    
    @State private var searchText: String = ""
    @State private var selectedFilter: String = "Todos"
    @State private var songs: [Song] = Song.sampleSongs
    @State private var isAddRiffPresented: Bool = false
    @State private var selectedSongForPlayer: Song? = nil
    
    let filterOptions = ["Todos", "📲 Salvos Offline", "Guitarra Solo", "Guitarra Base", "Baixo"]
    
    var filteredSongs: [Song] {
        let baseList: [Song]
        if selectedFilter == "📲 Salvos Offline" {
            baseList = offlineManager.savedSongs
        } else {
            baseList = songs
        }
        
        return baseList.filter { song in
            let matchesSearch = searchText.isEmpty || song.title.localizedCaseInsensitiveContains(searchText) || song.artist.localizedCaseInsensitiveContains(searchText)
            
            if selectedFilter == "Todos" || selectedFilter == "📲 Salvos Offline" {
                return matchesSearch
            } else {
                let matchesInstrument = song.tracks.contains { $0.instrument.rawValue == selectedFilter }
                return matchesSearch && matchesInstrument
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Biblioteca de Riffs")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text("Encontre músicas e selecione seu instrumento")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        
                        Button(action: {
                            isAddRiffPresented = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text("Novo Riff")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Buscar música, banda ou solo...", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                    .padding(.horizontal)
                    
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(filterOptions, id: \.self) { filter in
                                Button(action: {
                                    selectedFilter = filter
                                }) {
                                    HStack(spacing: 4) {
                                        if filter == "📲 Salvos Offline" {
                                            Image(systemName: "arrow.down.circle.fill")
                                                .font(.caption2)
                                        }
                                        Text(filter)
                                            .font(.caption.bold())
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == filter ? Color.cyan : Color.white.opacity(0.08))
                                    .foregroundColor(selectedFilter == filter ? .black : .white)
                                    .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Song List
                    if filteredSongs.isEmpty && selectedFilter == "📲 Salvos Offline" {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("Nenhuma tablatura salva offline")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Toque no botão de download em qualquer música para praticar sem internet.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(filteredSongs) { song in
                                    Button(action: {
                                        selectedSongForPlayer = song
                                    }) {
                                        HStack(spacing: 14) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(Color.purple.opacity(0.2))
                                                    .frame(width: 52, height: 52)
                                                
                                                Image(systemName: "guitars")
                                                    .font(.title2)
                                                    .foregroundColor(.purple)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack {
                                                    Text(song.title)
                                                        .font(.headline)
                                                        .foregroundColor(.white)
                                                        .lineLimit(1)
                                                    
                                                    if offlineManager.isSaved(id: song.id) {
                                                        Image(systemName: "arrow.down.circle.fill")
                                                            .font(.caption)
                                                            .foregroundColor(.cyan)
                                                    }
                                                }
                                                
                                                HStack(spacing: 8) {
                                                    Text(song.artist)
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                    
                                                    Text("•")
                                                        .foregroundColor(.gray)
                                                    
                                                    Text("\(song.bpm) BPM")
                                                        .font(.caption)
                                                        .foregroundColor(.cyan)
                                                }
                                                
                                                // Instruments Available Badges
                                                HStack(spacing: 4) {
                                                    ForEach(song.tracks) { track in
                                                        Text(track.instrument.rawValue)
                                                            .font(.system(size: 9, weight: .bold))
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.white.opacity(0.1))
                                                            .foregroundColor(.gray)
                                                            .cornerRadius(6)
                                                    }
                                                }
                                                .padding(.top, 2)
                                            }
                                            
                                            Spacer()
                                            
                                            // Botão de Download Rápido Offline
                                            Button(action: {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                offlineManager.toggleSave(song)
                                            }) {
                                                Image(systemName: offlineManager.isSaved(id: song.id) ? "checkmark.circle.fill" : "arrow.down.circle")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(offlineManager.isSaved(id: song.id) ? .cyan : .gray.opacity(0.6))
                                                    .padding(6)
                                            }
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                        .padding(14)
                                        .background(Color.white.opacity(0.04))
                                        .cornerRadius(18)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isAddRiffPresented) {
                AddRiffView()
            }
            .fullScreenCover(item: $selectedSongForPlayer) { song in
                TabPlayerView(song: song)
            }
            .onAppear {
                FirestoreManager.shared.fetchPublicSongs { fetchedSongs in
                    self.songs = fetchedSongs
                }
            }
        }
    }
}
