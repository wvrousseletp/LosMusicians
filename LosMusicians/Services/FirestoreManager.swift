import Foundation
import FirebaseFirestore

class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func saveUser(user: AppUser) {
        do {
            try db.collection("users").document(user.id).setData(from: user)
        } catch {
            print("Erro ao salvar usuário no Firestore: \(error.localizedDescription)")
        }
    }
    
    func fetchUser(userId: String, completion: @escaping (AppUser?) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists else {
                completion(nil)
                return
            }
            let user = try? snapshot.data(as: AppUser.self)
            completion(user)
        }
    }
    
    func fetchPublicSongs(completion: @escaping ([Song]) -> Void) {
        db.collection("songs").whereField("isPublic", isEqualTo: true).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                // Return sample songs if offline / empty
                completion(Song.sampleSongs)
                return
            }
            let songs = documents.compactMap { try? $0.data(as: Song.self) }
            completion(songs.isEmpty ? Song.sampleSongs : songs)
        }
    }
    
    func saveSong(song: Song, completion: @escaping (Bool) -> Void) {
        do {
            try db.collection("songs").document(song.id).setData(from: song)
            completion(true)
        } catch {
            print("Erro ao salvar música: \(error.localizedDescription)")
            completion(false)
        }
    }
}
