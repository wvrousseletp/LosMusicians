import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            // Fundo escuro premium com gradientes sutis
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.09),
                    Color(red: 0.08, green: 0.08, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Círculos de luz ambiente de fundo
            GeometryReader { proxy in
                Circle()
                    .fill(Color.cyan.opacity(0.12))
                    .blur(radius: 80)
                    .frame(width: 260, height: 260)
                    .offset(x: -50, y: -30)
                
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .blur(radius: 90)
                    .frame(width: 300, height: 300)
                    .offset(x: proxy.size.width - 200, y: proxy.size.height - 350)
            }
            
            VStack(spacing: 32) {
                Spacer()
                
                // Marca e Logo
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.25), .purple.opacity(0.25)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.cyan.opacity(0.6), .purple.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        
                        Image(systemName: "guitars.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Text("Los Musicians")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .cyan.opacity(0.3), radius: 10, x: 0, y: 4)
                        
                        Text("Evolua na guitarra com Inteligência Artificial e detecção de notas em tempo real.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                
                Spacer()
                
                // Bloco de Ação (Login Google)
                VStack(spacing: 16) {
                    if let error = authManager.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.4), lineWidth: 1)
                        )
                        .padding(.horizontal, 4)
                    }
                    
                    Button(action: {
                        authManager.signInWithGoogle()
                    }) {
                        HStack(spacing: 14) {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.red)
                                
                                Text("Continuar com Google")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(color: Color.white.opacity(0.15), radius: 15, x: 0, y: 8)
                    }
                    .disabled(authManager.isLoading)
                    
                    Text("Seus treinos, histórico e dados sincronizados em tempo real.")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }
                .padding(28)
                .background(Color.white.opacity(0.04))
                .cornerRadius(28)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 20)
            }
        }
    }
}
