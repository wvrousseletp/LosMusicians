import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct LosMusiciansApp: App {
    @StateObject private var authManager: AuthManager

    init() {
        // Safe Firebase initialization before any StateObjects!
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
        } else {
            print("⚠️ GoogleService-Info.plist não encontrado no bundle. Rodando em modo local/mock.")
        }
        
        _authManager = StateObject(wrappedValue: AuthManager())
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(authManager)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
