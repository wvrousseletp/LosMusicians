import SwiftUI

struct AITeacherSetupView: View {
    @State private var selectedInstrument = "Guitarra"
    @State private var selectedTechnique = "Palhetada Alternada"
    @State private var timeAvailable = 15
    @State private var isChallengeMode = false
    @State private var isGenerating = false
    
    let instruments = ["Guitarra", "Violão", "Baixo", "Bateria", "Teclado"]
    let techniques = [
        "Guitarra": ["Palhetada Alternada", "Sweep Picking", "Legato", "Tapping", "Bends & Vibrato"],
        "Violão": ["Fingerstyle", "Batidas", "Arpejos", "Harmônicos"],
        "Baixo": ["Slap", "Pizzicato", "Palheta", "Tapping"],
        "Bateria": ["Rudimentos", "Grooves Básicos", "Viradas", "Bumbo Duplo"],
        "Teclado": ["Acordes", "Escalas", "Arpejos", "Independência das Mãos"]
    ]
    let times = [5, 10, 15, 30, 45, 60]
    
    @State private var navigateToPlayer = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Instrumento e Técnica")) {
                    Picker("Instrumento", selection: $selectedInstrument) {
                        ForEach(instruments, id: \.self) { instrument in
                            Text(instrument).tag(instrument)
                        }
                    }
                    .onChange(of: selectedInstrument) { newValue in
                        selectedTechnique = techniques[newValue]?.first ?? ""
                    }
                    
                    Picker("Técnica Foco", selection: $selectedTechnique) {
                        ForEach(techniques[selectedInstrument] ?? [], id: \.self) { technique in
                            Text(technique).tag(technique)
                        }
                    }
                }
                
                Section(header: Text("Tempo e Intensidade")) {
                    Picker("Tempo Disponível", selection: $timeAvailable) {
                        ForEach(times, id: \.self) { time in
                            Text("\(time) min").tag(time)
                        }
                    }
                    
                    Toggle(isOn: $isChallengeMode) {
                        VStack(alignment: .leading) {
                            Text("Modo Desafio")
                                .font(.headline)
                            Text(isChallengeMode ? "IA criará um exercício com padrões novos e difíceis." : "IA criará um exercício focado em aquecimento e precisão.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(.orange)
                }
                
                Section {
                    Button(action: {
                        generateExercise()
                    }) {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                                Text("A IA está compondo...")
                            } else {
                                Image(systemName: "sparkles")
                                Text("Gerar Exercício com IA")
                            }
                            Spacer()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(isGenerating ? Color.gray : Color.orange)
                        .cornerRadius(10)
                    }
                    .disabled(isGenerating)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Professor IA 🤖")
            .background(
                NavigationLink(
                    destination: AITeacherPlayerView(
                        instrument: selectedInstrument,
                        technique: selectedTechnique,
                        timeAvailable: timeAvailable,
                        isChallengeMode: isChallengeMode,
                        alphaTex: generatedAlphaTex
                    ),
                    isActive: $navigateToPlayer,
                    label: { EmptyView() }
                )
                .hidden()
            )
            .alert(item: Binding<AlertItem?>(
                get: { errorMessage != nil ? AlertItem(message: errorMessage!) : nil },
                set: { _ in errorMessage = nil }
            )) { alertItem in
                Alert(title: Text("Erro na IA"), message: Text(alertItem.message), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    @State private var generatedAlphaTex: String = ""
    @State private var errorMessage: String?
    
    private func generateExercise() {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let tex = try await GeminiService.shared.generateExercise(
                    instrument: selectedInstrument,
                    technique: selectedTechnique,
                    timeAvailable: timeAvailable,
                    isChallengeMode: isChallengeMode
                )
                
                await MainActor.run {
                    self.generatedAlphaTex = tex
                    self.isGenerating = false
                    self.navigateToPlayer = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isGenerating = false
                }
            }
        }
    }
}

#Preview {
    AITeacherSetupView()
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}
