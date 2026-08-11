import Foundation

struct ExerciseModel: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var instrument: String
    var technique: String
    var alphaTex: String
    var score: Int = 0
    var maxScore: Int = 0
    var dateCreated: Date = Date()
}

class SavedExercisesManager: ObservableObject {
    static let shared = SavedExercisesManager()
    
    @Published var savedExercises: [ExerciseModel] = []
    
    private let defaultsKey = "saved_exercises"
    
    init() {
        loadExercises()
    }
    
    func loadExercises() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let exercises = try? JSONDecoder().decode([ExerciseModel].self, from: data) {
            self.savedExercises = exercises.sorted(by: { $0.dateCreated > $1.dateCreated })
        }
    }
    
    func addExercise(_ exercise: ExerciseModel) {
        savedExercises.insert(exercise, at: 0)
        saveExercises()
    }
    
    func updateExercise(_ exercise: ExerciseModel) {
        if let index = savedExercises.firstIndex(where: { $0.id == exercise.id }) {
            savedExercises[index] = exercise
            saveExercises()
        }
    }
    
    func saveExercises() {
        if let data = try? JSONEncoder().encode(savedExercises) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}
