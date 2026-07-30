import Foundation
import SwiftData

@Model
class ExerciseModel {
    var id: UUID
    var title: String
    var instrument: String
    var technique: String
    var alphaTex: String
    var score: Int
    var maxScore: Int
    var dateCreated: Date
    
    init(id: UUID = UUID(), title: String, instrument: String, technique: String, alphaTex: String, score: Int = 0, maxScore: Int = 0, dateCreated: Date = Date()) {
        self.id = id
        self.title = title
        self.instrument = instrument
        self.technique = technique
        self.alphaTex = alphaTex
        self.score = score
        self.maxScore = maxScore
        self.dateCreated = dateCreated
    }
}
