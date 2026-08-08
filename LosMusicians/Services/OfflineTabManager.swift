import Foundation
import SwiftUI

/// Gerenciador de armazenamento local para reprodução de tablaturas 100% offline e histórico recente
final class OfflineTabManager: ObservableObject {
    static let shared = OfflineTabManager()
    
    private let storageKey = "LosMusicians_OfflineSavedSongs"
    private let recentSongKey = "LosMusicians_RecentSong"
    
    @Published var savedSongs: [Song] = []
    @Published var recentSong: Song? = nil
    
    private init() {
        loadSavedSongs()
        loadRecentSong()
    }
    
    /// Carrega as músicas salvas localmente
    func loadSavedSongs() {
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                let decoded = try JSONDecoder().decode([Song].self, from: data)
                self.savedSongs = decoded
                return
            } catch {
                print("Erro ao decodificar músicas offline:", error)
            }
        }
        
        // Se ainda não houver dados, inicializa com as músicas de exemplo para teste imediato
        self.savedSongs = Song.sampleSongs
        persistSongs()
    }
    
    /// Carrega a última música praticada
    func loadRecentSong() {
        if let data = UserDefaults.standard.data(forKey: recentSongKey),
           let decoded = try? JSONDecoder().decode(Song.self, from: data) {
            self.recentSong = decoded
        } else {
            // Padrão inicial
            self.recentSong = Song.sampleSongs.first
        }
    }
    
    /// Registra a música no histórico recente
    func recordRecent(song: Song) {
        self.recentSong = song
        if let data = try? JSONEncoder().encode(song) {
            UserDefaults.standard.set(data, forKey: recentSongKey)
        }
    }
    
    /// Salva ou atualiza uma música no armazenamento local
    func saveSong(_ song: Song) {
        if let index = savedSongs.firstIndex(where: { $0.id == song.id }) {
            savedSongs[index] = song
        } else {
            savedSongs.insert(song, at: 0)
        }
        persistSongs()
    }
    
    /// Remove uma música salva
    func removeSong(id: String) {
        savedSongs.removeAll(where: { $0.id == id })
        persistSongs()
    }
    
    /// Alterna estado de salvamento (Adicionar / Remover)
    func toggleSave(_ song: Song) {
        if isSaved(id: song.id) {
            removeSong(id: song.id)
        } else {
            saveSong(song)
        }
    }
    
    /// Verifica se uma música já está disponível offline
    func isSaved(id: String) -> Bool {
        return savedSongs.contains(where: { $0.id == id })
    }
    
    private func persistSongs() {
        do {
            let data = try JSONEncoder().encode(savedSongs)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Erro ao persistir músicas offline:", error)
        }
    }
}
