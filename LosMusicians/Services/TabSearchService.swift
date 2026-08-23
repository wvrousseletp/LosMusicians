import Foundation
import FirebaseFirestore

class TabSearchService: ObservableObject {
    static let shared = TabSearchService()
    
    @Published var searchResults: [Song] = []
    @Published var isSearching: Bool = false
    @Published var errorMessage: String? = nil
    
    func searchSongs(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces).lowercased()
        
        guard !trimmedQuery.isEmpty else {
            DispatchQueue.main.async {
                self.searchResults = []
            }
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        // Em um app real com Firestore, você usaria um serviço como Algolia ou ElasticSearch para 
        // busca de texto completo. Como paliativo no Firestore puro, vamos baixar as músicas públicas
        // e filtrar localmente, já que nosso banco inicial é pequeno.
        FirestoreManager.shared.fetchPublicSongs { songs in
            DispatchQueue.main.async {
                let filtered = songs.filter { song in
                    song.title.lowercased().contains(trimmedQuery) ||
                    song.artist.lowercased().contains(trimmedQuery)
                }
                
                self.searchResults = filtered
                self.isSearching = false
                
                if filtered.isEmpty {
                    // Se não achar, podemos no futuro chamar o Gemini aqui para gerar
                    self.errorMessage = "Nenhuma música encontrada no banco de dados."
                }
            }
        }
    }
}
