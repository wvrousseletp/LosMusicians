import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedSongForPlayer: Song? = nil
    
    var user: AppUser {
        authManager.currentUser ?? AppUser(id: "guest", name: "Músico", email: "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header com Perfil e Streak
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Olá, \(user.name)! 👋")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                Text("Pronto para o treino de hoje?")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Streak Flame Badge (Estilo Duolingo)
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                    .font(.headline)
                                Text("\(user.streakDays)")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.orange, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                        
                        // Card de Nível com Curva Progressiva de XP
                        VStack(spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text("Nível \(user.level)")
                                            .font(.caption.bold())
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.purple.opacity(0.3))
                                            .foregroundColor(.purple)
                                            .cornerRadius(8)
                                        
                                        Text("Shredder")
                                            .font(.caption.bold())
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text("\(user.xp) XP Total")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "guitars.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        LinearGradient(colors: [.cyan, .purple], startPoint: .top, endPoint: .bottom)
                                    )
                            }
                            
                            // Barra de XP para Próximo Nível (Progressiva)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Progresso para o Nível \(user.level + 1)")
                                        .font(.footnote.bold())
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(user.xpInCurrentLevel) / \(user.xpNeededForNextLevel) XP")
                                        .font(.footnote.bold())
                                        .foregroundColor(.purple)
                                }
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(height: 10)
                                        
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing))
                                            .frame(width: geo.size.width * CGFloat(user.levelProgressFraction), height: 10)
                                    }
                                }
                                .frame(height: 10)
                            }
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            // Meta Diária Bar
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Meta Diária: \(user.todayPracticeMinutes) / \(user.dailyGoalMinutes) min")
                                        .font(.footnote.bold())
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(Int(min(1.0, Double(user.todayPracticeMinutes) / Double(user.dailyGoalMinutes)) * 100))%")
                                        .font(.footnote.bold())
                                        .foregroundColor(.cyan)
                                }
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(height: 8)
                                        
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                                            .frame(width: geo.size.width * CGFloat(min(1.0, Double(user.todayPracticeMinutes) / Double(user.dailyGoalMinutes))), height: 8)
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // Prática Rápida (Recomendados)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Destaques para Treino")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ForEach(Song.sampleSongs) { song in
                                Button(action: {
                                    selectedSongForPlayer = song
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "music.note")
                                            .font(.title2)
                                            .foregroundColor(.cyan)
                                            .frame(width: 48, height: 48)
                                            .background(Color.cyan.opacity(0.15))
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(song.title)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text(song.artist)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "play.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.cyan)
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(16)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $selectedSongForPlayer) { song in
                TabPlayerView(song: song)
            }
        }
    }
}
