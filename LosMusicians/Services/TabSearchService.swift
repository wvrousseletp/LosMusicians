import Foundation

struct SongSearchResult: Identifiable, Codable {
    var id: Int { songId }
    let songId: Int
    let artistId: Int
    let artist: String
    let title: String
    let hasChords: Bool
    let hasPlayer: Bool
}

class TabSearchService: ObservableObject {
    static let shared = TabSearchService()
    
    @Published var searchResults: [SongSearchResult] = []
    @Published var isSearching: Bool = false
    @Published var errorMessage: String? = nil
    
    private var currentSearchTask: Task<Void, Never>?
    
    func searchSongs(query: String) {
        currentSearchTask?.cancel()
        
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            DispatchQueue.main.async {
                self.searchResults = []
            }
            return
        }
        
        currentSearchTask = Task {
            await performSearch(query: query)
        }
    }
    
    @MainActor
    private func performSearch(query: String) async {
        isSearching = true
        errorMessage = nil
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.songsterr.com/api/songs?size=50&pattern=\(encodedQuery)") else {
            self.errorMessage = "URL inválida"
            self.isSearching = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if Task.isCancelled { return }
            
            let decoder = JSONDecoder()
            let results = try decoder.decode([SongSearchResult].self, from: data)
            
            self.searchResults = results
            self.isSearching = false
        } catch {
            if !Task.isCancelled {
                self.errorMessage = "Erro na busca: \(error.localizedDescription)"
                self.isSearching = false
            }
        }
    }
    
    // Simula a obtenção da tablatura real
    func fetchMockAlphaTex(for result: SongSearchResult) -> String {
        return """
        \\title "\(result.title)"
        \\artist "\(result.artist)"
        
        :4 0.6 0.6 0.6 0.6 | 3.5 3.5 3.5 3.5 | 5.5 5.5 5.5 5.5 | 0.6 0.6 0.6 0.6
        """
    }
}
