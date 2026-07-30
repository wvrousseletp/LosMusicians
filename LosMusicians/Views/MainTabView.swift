import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.scenePhase) var scenePhase
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

                    SavedExercisesView()
                        .tabItem {
                            Label("Meus Treinos", systemImage: "music.note.list")
                        }
                        .tag(2)
                        
                    LeaderboardView()
                        .tabItem {
                            Label("Ranking", systemImage: "trophy.fill")
                        }
                        .tag(3)
                    
                    ProfileView()
                        .tabItem {
                            Label("Perfil", systemImage: "person.fill")
                        }
                        .tag(4)
                }
                .accentColor(.cyan)
                .onAppear {
                    NotificationManager.shared.requestPermission()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .background {
                        NotificationManager.shared.scheduleStreakReminder()
                    }
                }
            } else {
                LoginView()
            }
        }
    }
}
