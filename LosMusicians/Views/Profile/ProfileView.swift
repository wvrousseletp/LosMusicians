import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var user: AppUser {
        authManager.currentUser ?? AppUser(id: "guest", name: "Músico", email: "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Avatar & Info
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 96, height: 96)
                                
                                Image(systemName: user.avatarName)
                                    .font(.system(size: 48))
                                    .foregroundColor(.white)
                            }
                            
                            Text(user.name)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        
                        // Gamification Overview Stats Grid
                        HStack(spacing: 14) {
                            StatCard(title: "Ofensiva", value: "\(user.streakDays) Dias", icon: "flame.fill", color: .orange)
                            StatCard(title: "Nível", value: "Nível \(user.level)", icon: "star.fill", color: .purple)
                            StatCard(title: "XP Total", value: "\(user.xp)", icon: "sparkles", color: .yellow)
                        }
                        .padding(.horizontal)
                        
                        // Badges / Conquistas (Estilo Duolingo)
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Conquistas Desbloqueadas")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(user.badges) { badge in
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(badge.isUnlocked ? Color.amberGold.opacity(0.2) : Color.white.opacity(0.05))
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: badge.iconName)
                                                .font(.title2)
                                                .foregroundColor(badge.isUnlocked ? .yellow : .gray)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(badge.title)
                                                .font(.headline)
                                                .foregroundColor(badge.isUnlocked ? .white : .gray)
                                            Text(badge.description)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        if badge.isUnlocked {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundColor(.yellow)
                                                .font(.title3)
                                        } else {
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Logout Button
                        Button(action: {
                            authManager.logout()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sair da Conta")
                                    .font(.headline.bold())
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

extension Color {
    static let amberGold = Color(red: 1.0, green: 0.75, blue: 0.0)
}
