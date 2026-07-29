import Foundation
import SwiftUI
import FirebaseAuth

class AuthManager: ObservableObject {
    @Published var currentUser: AppUser? = nil
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    init() {
        // Mock user for instant preview / offline test
        self.currentUser = AppUser(
            id: "mock_user_1",
            name: "Músico Rocker",
            email: "musico@losmusicians.com",
            xp: 350,
            streakDays: 5,
            lastPracticeDate: Date(),
            dailyGoalMinutes: 15,
            todayPracticeMinutes: 10
        )
        self.isAuthenticated = true
        
        listenToAuthChanges()
    }
    
    func listenToAuthChanges() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                self.fetchUserData(userId: user.uid)
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
                    // Fallback to mock for seamless UI testing
                    self?.signInMockUser(email: email)
                } else if let uid = result?.user.uid {
                    self?.fetchUserData(userId: uid)
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
                    self?.signInMockUser(email: email, name: name)
                } else if let uid = result?.user.uid {
                    let newUser = AppUser(id: uid, name: name, email: email)
                    self?.currentUser = newUser
                    self?.isAuthenticated = true
                    FirestoreManager.shared.saveUser(user: newUser)
                }
            }
        }
    }
    
    func logout() {
        try? Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    private func signInMockUser(email: String, name: String = "Novo Músico") {
        self.currentUser = AppUser(id: UUID().uuidString, name: name, email: email, xp: 100, streakDays: 1)
        self.isAuthenticated = true
    }
    
    private func fetchUserData(userId: String) {
        FirestoreManager.shared.fetchUser(userId: userId) { [weak self] user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.currentUser = user
                } else {
                    self?.currentUser = AppUser(id: userId, name: "Músico", email: "user@losmusicians.com")
                }
                self?.isAuthenticated = true
            }
        }
    }
    
    func addPracticeTime(minutes: Int) {
        guard var user = currentUser else { return }
        user.todayPracticeMinutes += minutes
        user.xp += minutes * 10 // 10 XP por minuto de prática!
        
        // Atualiza streak se for um novo dia
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
