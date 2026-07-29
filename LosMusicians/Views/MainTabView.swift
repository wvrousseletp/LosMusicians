import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab: Int = 0
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tabItem {
                            Label("Treino", systemImage: "flame.fill")
                        }
                        .tag(0)
                    
                    AITeacherSetupView()
                        .tabItem {
                            Label("Professor IA", systemImage: "sparkles")
                        }
                        .tag(1)

                    SongLibraryView()
                        .tabItem {
                            Label("Biblioteca", systemImage: "music.note.list")
                        }
                        .tag(2)
                    
                    ProfileView()
                        .tabItem {
                            Label("Perfil", systemImage: "person.fill")
                        }
                        .tag(3)
                }
                .accentColor(.cyan)
            } else {
                LoginView()
            }
        }
    }
}
