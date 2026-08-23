import SwiftUI

struct SearchResultsView: View {
    @StateObject private var searchService = TabSearchService.shared
    @State private var query: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedResult: Song? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Música, artista ou banda...", text: $query)
                            .foregroundColor(.white)
                            .onChange(of: query) { newValue in
                                // Debounce simple search
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if query == newValue {
                                        searchService.searchSongs(query: newValue)
                                    }
                                }
                            }
                        
                        if !query.isEmpty {
                            Button(action: {
                                query = ""
                                searchService.searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding()
                    
                    if searchService.isSearching {
                        Spacer()
                        ProgressView("Buscando tablaturas...")
                            .foregroundColor(.gray)
                        Spacer()
                    } else if let error = searchService.errorMessage {
                        Spacer()
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    } else if searchService.searchResults.isEmpty && !query.isEmpty {
                        Spacer()
                        Text("Nenhuma tablatura encontrada.")
                            .foregroundColor(.gray)
                        Spacer()
                    } else {
                        List {
                            ForEach(searchService.searchResults) { result in
                                Button(action: {
                                    selectedResult = result
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "music.note.list")
                                            .font(.title2)
                                            .foregroundColor(.purple)
                                            .frame(width: 40, height: 40)
                                            .background(Color.purple.opacity(0.2))
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(result.title)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text(result.artist)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    }
                                    .padding(.vertical, 8)
                                }
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Pesquisa Global")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fechar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedResult) { result in
            AILessonPlanView(song: result)
        }
    }
}
