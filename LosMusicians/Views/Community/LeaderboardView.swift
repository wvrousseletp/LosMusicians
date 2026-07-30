import SwiftUI
import FirebaseFirestore

struct LeaderboardUser: Identifiable {
    var id: String
    var displayName: String
    var xp: Int
}

class LeaderboardViewModel: ObservableObject {
    @Published var users: [LeaderboardUser] = []
    private var db = Firestore.firestore()
    
    func fetchLeaderboard() {
        // Le a colecao 'users' ordenada por XP
        db.collection("users")
            .order(by: "xp", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Erro ao buscar leaderboard: \(String(describing: error))")
                    return
                }
                
                DispatchQueue.main.async {
                    self.users = documents.map { doc in
                        let data = doc.data()
                        return LeaderboardUser(
                            id: doc.documentID,
                            displayName: data["displayName"] as? String ?? "Usuário Anônimo",
                            xp: data["xp"] as? Int ?? 0
                        )
                    }
                }
            }
    }
}

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.users.isEmpty {
                    Text("Carregando ranking...")
                        .foregroundColor(.gray)
                }
                
                ForEach(viewModel.users.indices, id: \.self) { index in
                    let user = viewModel.users[index]
                    HStack {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(index < 3 ? .yellow : .gray)
                            .frame(width: 30, alignment: .leading)
                        
                        VStack(alignment: .leading) {
                            Text(user.displayName)
                                .font(.headline)
                                .foregroundColor(user.id == authManager.user?.uid ? .cyan : .white)
                            
                            if user.id == authManager.user?.uid {
                                Text("Você")
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.cyan.opacity(0.3))
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(user.xp) XP")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Global Leaderboard 🏆")
            .onAppear {
                viewModel.fetchLeaderboard()
            }
        }
    }
}
