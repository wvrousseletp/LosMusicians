import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedCategory: String = "Todas"
    
    var user: AppUser {
        authManager.currentUser ?? AppUser(id: "guest", name: "Músico", email: "")
    }
    
    let badgeCategories = ["Todas", "Iniciante", "Consistência", "Mestria", "Lendário"]
    
    var filteredBadges: [Badge] {
        if selectedCategory == "Todas" {
            return user.badges
        } else {
            return user.badges.filter { $0.category == selectedCategory }
        }
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
                        
                        // Badges / Conquistas por Categoria
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Conquistas (\(user.badges.filter({ $0.isUnlocked }).count)/\(user.badges.count))")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Category Pills
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(badgeCategories, id: \.self) { cat in
                                        Button(action: {
                                            selectedCategory = cat
                                        }) {
                                            Text(cat)
                                                .font(.caption.bold())
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 6)
                                                .background(selectedCategory == cat ? Color.purple : Color.white.opacity(0.08))
                                                .foregroundColor(selectedCategory == cat ? .white : .gray)
                                                .cornerRadius(16)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(filteredBadges) { badge in
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(badgeColor(badge).opacity(badge.isUnlocked ? 0.25 : 0.05))
                                                .frame(width: 52, height: 52)
                                            
                                            Image(systemName: badge.iconName)
                                                .font(.title2)
                                                .foregroundColor(badge.isUnlocked ? badgeColor(badge) : .gray.opacity(0.5))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Text(badge.title)
                                                    .font(.headline)
                                                    .foregroundColor(badge.isUnlocked ? .white : .gray)
                                                
                                                Text(badge.category)
                                                    .font(.system(size: 9, weight: .bold))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(badgeColor(badge).opacity(0.2))
                                                    .foregroundColor(badgeColor(badge))
                                                    .cornerRadius(6)
                                            }
                                            
                                            Text(badge.description)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        if badge.isUnlocked {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundColor(badgeColor(badge))
                                                .font(.title3)
                                        } else {
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(.gray.opacity(0.4))
                                        }
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(badge.isUnlocked ? badgeColor(badge).opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
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
    
    private func badgeColor(_ badge: Badge) -> Color {
        switch badge.category {
        case "Iniciante": return .cyan
        case "Consistência": return .orange
        case "Mestria": return .purple
        case "Lendário": return .yellow
        default: return .blue
        }
    }
}
