import Foundation

struct AppUser: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var avatarName: String = "person.crop.circle.fill"
    
    // Gamificação (Estilo Duolingo)
    var xp: Int = 0
    var level: Int {
        return (xp / 100) + 1
    }
    var streakDays: Int = 0
    var lastPracticeDate: Date? = nil
    var dailyGoalMinutes: Int = 15
    var todayPracticeMinutes: Int = 0
    
    // Conquistas
    var badges: [Badge] = Badge.defaultBadges
}

struct Badge: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var description: String
    var iconName: String
    var isUnlocked: Bool
    
    static var defaultBadges: [Badge] {
        [
            Badge(id: "b1", title: "Primeiro Riff", description: "Tocou seu primeiro solo no app", iconName: "guitars.fill", isUnlocked: true),
            Badge(id: "b2", title: "Ofensiva de 3 Dias", description: "Estudou por 3 dias seguidos", iconName: "flame.fill", isUnlocked: false),
            Badge(id: "b3", title: "Mestre do Tempo", description: "Usou a função de desacelerar 5 vezes", iconName: "speedometer", isUnlocked: true),
            Badge(id: "b4", title: "Criador de Solos", description: "Adicionou seu primeiro riff personalizado", iconName: "music.note.list", isUnlocked: false)
        ]
    }
}
