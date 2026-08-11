import SwiftUI

struct OfflineLibraryView: View {
    @ObservedObject var offlineManager = OfflineTabManager.shared
    @State private var searchText = ""
    @State private var selectedSong: Song? = nil
    
    var filteredSongs: [Song] {
        if searchText.isEmpty {
            return offlineManager.savedSongs
        } else {
            return offlineManager.savedSongs.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.artist.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Minimalista
                    HStack {
                        Text("Modo Offline")
                            .font(.title.weight(.bold))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Buscar em downloads...", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    if offlineManager.savedSongs.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("Nenhuma tablatura baixada")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Salve músicas na nuvem usando o botão de download no Player para acessar sem internet.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredSongs) { song in
                                    Button(action: {
                                        selectedSong = song
                                    }) {
                                        HStack(spacing: 16) {
                                            // Capa Mock
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 50, height: 50)
                                                Image(systemName: "music.note")
                                                    .foregroundColor(.white)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(song.title)
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                Text(song.artist)
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.title3)
                                        }
                                        .padding(12)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(16)
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedSong) { song in
                TabPlayerView(song: song)
            }
        }
    }
}
