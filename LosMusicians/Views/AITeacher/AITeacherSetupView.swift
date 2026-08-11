import SwiftUI

struct AITeacherSetupView: View {
    @StateObject private var manager = SavedExercisesManager.shared
    
    @State private var currentSection: Int = 0 // 0: Gerador IA, 1: Exercícios Salvos da IA
    
    // Configurações do Gerador
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
    @State private var activeExercise: ExerciseModel? = nil
    @State private var generatedAlphaTex: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Picker no topo para alternar entre Gerador e Exercícios da IA
                Picker("Aba", selection: $currentSection) {
                    Text("✨ Gerar Novo").tag(0)
                    Text("📚 Exercícios da IA (\(manager.savedExercises.count))").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(red: 15/255, green: 15/255, blue: 20/255))
                
                if currentSection == 0 {
                    generatorFormView
                } else {
                    savedExercisesListView
                }
            }
            .background(Color(red: 15/255, green: 15/255, blue: 19/255).edgesIgnoringSafeArea(.all))
            .navigationTitle("Professor IA 🤖")
            .background(
                NavigationLink(
                    destination: Group {
                        if let exercise = activeExercise {
                            AITeacherPlayerView(
                                instrument: exercise.instrument,
                                technique: exercise.technique,
                                timeAvailable: timeAvailable,
                                isChallengeMode: exercise.title.contains("Desafio"),
                                alphaTex: exercise.alphaTex,
                                exercise: exercise
                            )
                        } else {
                            AITeacherPlayerView(
                                instrument: selectedInstrument,
                                technique: selectedTechnique,
                                timeAvailable: timeAvailable,
                                isChallengeMode: isChallengeMode,
                                alphaTex: generatedAlphaTex,
                                exercise: nil
                            )
                        }
                    },
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
    
    // MARK: - Tela do Gerador
    private var generatorFormView: some View {
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
                            Text("A IA está compondo e salvando...")
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
    }
    
    // MARK: - Aba de Exercícios Salvos da IA
    private var savedExercisesListView: some View {
        Group {
            if manager.savedExercises.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("Nenhum exercício gerado ainda")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Use a aba 'Gerar Novo' para que o Professor IA crie um treino personalizado de tablatura para você.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    Button(action: {
                        withAnimation {
                            currentSection = 0
                        }
                    }) {
                        Label("Criar Primeiro Exercício", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.orange)
                            .cornerRadius(25)
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
            } else {
                List {
                    ForEach(manager.savedExercises) { exercise in
                        Button(action: {
                            self.activeExercise = exercise
                            self.navigateToPlayer = true
                        }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(exercise.title.contains("Desafio") ? Color.orange.opacity(0.2) : Color.cyan.opacity(0.2))
                                        .frame(width: 48, height: 48)
                                    
                                    Image(systemName: exercise.title.contains("Desafio") ? "bolt.fill" : "music.note")
                                        .foregroundColor(exercise.title.contains("Desafio") ? .orange : .cyan)
                                        .font(.system(size: 20))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.title)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 8) {
                                        Text(exercise.instrument)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(6)
                                            .foregroundColor(.gray)
                                        
                                        Text(exercise.technique)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    if exercise.maxScore > 0 {
                                        Text("Pontuação: \(exercise.score)/\(exercise.maxScore)")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.cyan)
                            }
                            .padding(.vertical, 6)
                        }
                        .listRowBackground(Color(red: 25/255, green: 25/255, blue: 30/255))
                    }
                    .onDelete(perform: deleteExercises)
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
    
    private func deleteExercises(at offsets: IndexSet) {
        manager.savedExercises.remove(atOffsets: offsets)
        manager.saveExercises()
    }
    
    // MARK: - Geração e Salvamento Automático
    private func generateExercise() {
        isGenerating = true
        errorMessage = nil
        activeExercise = nil
        
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
                    
                    // Salva automaticamente no banco SwiftData imediatamente após a criação pela IA
                    let newExercise = ExerciseModel(
                        title: "\(selectedTechnique) - \(isChallengeMode ? "Desafio" : "Aquecimento")",
                        instrument: selectedInstrument,
                        technique: selectedTechnique,
                        alphaTex: tex,
                        score: 0,
                        maxScore: 0,
                        dateCreated: Date()
                    )
                    
                    SavedExercisesManager.shared.addExercise(newExercise)
                    
                    self.activeExercise = newExercise
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

struct AITeacherSetupView_Previews: PreviewProvider {
    static var previews: some View {
        AITeacherSetupView()
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}
