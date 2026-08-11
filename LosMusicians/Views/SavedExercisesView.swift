import SwiftUI
struct SavedExercisesView: View {
    @StateObject private var manager = SavedExercisesManager.shared
    
    var body: some View {
        NavigationView {
            List {
                if manager.savedExercises.isEmpty {
                    Text("Nenhum exercício salvo ainda. Vá ao Professor IA para gerar novos treinos!")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(manager.savedExercises) { exercise in
                        NavigationLink(destination: AITeacherPlayerView(
                            instrument: exercise.instrument,
                            technique: exercise.technique,
                            timeAvailable: 0,
                            isChallengeMode: exercise.title.contains("Desafio"),
                            alphaTex: exercise.alphaTex,
                            exercise: exercise
                        )) {
                            VStack(alignment: .leading) {
                                Text(exercise.title)
                                    .font(.headline)
                                    .foregroundColor(.cyan)
                                
                                HStack {
                                    Text(exercise.instrument)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("Acertos: \(exercise.score)/\(exercise.maxScore)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                
                                Text(exercise.dateCreated, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Meus Exercícios")
        }
    }
}
