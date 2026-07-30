import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email: String = ""
    @State private var pass: String = ""
    @State private var name: String = ""
    @State private var isRegisterMode: Bool = false
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.10)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // App Logo
                VStack(spacing: 12) {
                    Image(systemName: "guitars.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    Text("Los Musicians")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Estudo Musical Gamificado")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Form Card
                VStack(spacing: 16) {
                    if isRegisterMode {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Nome").font(.caption).foregroundColor(.gray)
                            TextField("Seu nome", text: $name)
                                .padding(14)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email").font(.caption).foregroundColor(.gray)
                        TextField("seu@email.com", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(14)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Senha").font(.caption).foregroundColor(.gray)
                        SecureField("••••••••", text: $pass)
                            .padding(14)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    
                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        if isRegisterMode {
                            authManager.register(name: name, email: email, pass: pass)
                        } else {
                            authManager.login(email: email, pass: pass)
                        }
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isRegisterMode ? "CRIAR CONTA" : "ENTRAR NO APP")
                                    .font(.headline.bold())
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(16)
                    }
                    .padding(.top, 8)
                    
                    Button(action: {
                        withAnimation {
                            isRegisterMode.toggle()
                        }
                    }) {
                        Text(isRegisterMode ? "Já tem conta? Entrar" : "Não tem conta? Cadastrar-se")
                            .font(.subheadline.bold())
                            .foregroundColor(.cyan)
                    }
                    .padding(.top, 4)
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)
                    
                    Button(action: {
                        authManager.signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("Continuar com Google")
                                .font(.headline.bold())
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                }
                .padding(24)
                .background(Color.white.opacity(0.05))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}
