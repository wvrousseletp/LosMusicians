import Foundation
import SwiftUI
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

class AuthManager: ObservableObject {
    @Published var currentUser: AppUser? = nil
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    init() {
        // Verifica se já existe um usuário autenticado no Keychain do iOS
        if let user = Auth.auth().currentUser {
            self.isAuthenticated = true
            let name = user.displayName ?? "Músico"
            let email = user.email ?? ""
            self.currentUser = AppUser(id: user.uid, name: name, email: email)
            self.fetchUserData(userId: user.uid, authUser: user)
        } else {
            self.isAuthenticated = false
        }
        
        listenToAuthChanges()
    }
    
    func listenToAuthChanges() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let user = user {
                    self.isAuthenticated = true
                    if self.currentUser == nil {
                        let name = user.displayName ?? "Músico"
                        let email = user.email ?? ""
                        self.currentUser = AppUser(id: user.uid, name: name, email: email)
                    }
                    self.fetchUserData(userId: user.uid, authUser: user)
                } else {
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    func login(email: String, pass: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: pass) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else if let user = result?.user {
                    self?.isAuthenticated = true
                    self?.fetchUserData(userId: user.uid, authUser: user)
                }
            }
        }
    }
    
    func register(name: String, email: String, pass: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: pass) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else if let uid = result?.user.uid {
                    let newUser = AppUser(id: uid, name: name, email: email)
                    self?.currentUser = newUser
                    self?.isAuthenticated = true
                    FirestoreManager.shared.saveUser(user: newUser)
                }
            }
        }
    }
    
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.errorMessage = "Configuração do Firebase não encontrada."
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene ?? UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? windowScene.windows.first?.rootViewController else {
            self.errorMessage = "Não foi possível exibir a tela de autenticação."
            return
        }

        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }

        self.isLoading = true
        self.errorMessage = nil

        GIDSignIn.sharedInstance.signIn(withPresenting: topController) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    let nsError = error as NSError
                    if nsError.domain == kGIDSignInErrorDomain && nsError.code == -5 {
                        return
                    }
                    self.errorMessage = error.localizedDescription
                }
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Falha ao obter credenciais do Google."
                }
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    if let authUser = authResult?.user {
                        self.isAuthenticated = true
                        self.fetchUserData(userId: authUser.uid, authUser: authUser)
                    }
                }
            }
        }
    }
    
    func logout() {
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    private func fetchUserData(userId: String, authUser: FirebaseAuth.User?) {
        DispatchQueue.main.async {
            self.isAuthenticated = true
        }
        
        FirestoreManager.shared.fetchUser(userId: userId) { [weak self] user in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let user = user {
                    self.currentUser = user
                } else {
                    let name = authUser?.displayName ?? "Músico"
                    let email = authUser?.email ?? "user@losmusicians.com"
                    let newUser = AppUser(id: userId, name: name, email: email)
                    self.currentUser = newUser
                    FirestoreManager.shared.saveUser(user: newUser)
                }
                self.isAuthenticated = true
            }
        }
    }
    
    func addPracticeTime(minutes: Int) {
        guard var user = currentUser else { return }
        user.todayPracticeMinutes += minutes
        user.xp += minutes * 10 
        
        let calendar = Calendar.current
        if let lastDate = user.lastPracticeDate {
            if !calendar.isDateInToday(lastDate) {
                user.streakDays += 1
            }
        } else {
            user.streakDays = 1
        }
        user.lastPracticeDate = Date()
        
        self.currentUser = user
        FirestoreManager.shared.saveUser(user: user)
    }
}
