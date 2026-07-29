import Foundation

struct AppUser: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var avatarName: String = "person.crop.circle.fill"
    
    // Gamificação (Estilo Duolingo com Curva Progressiva)
    var xp: Int = 0
    
    /// Nível calculado com curva progressiva: cada nível exige mais XP que o anterior
    /// Fórmula: XP acumulado para Nível L = 50 * L * (L - 1)
    var level: Int {
        var lvl = 1
        while xp >= xpRequiredForLevel(lvl + 1) {
            lvl += 1
        }
        return lvl
    }
    
    /// XP total necessário para alcançar o nível N
    func xpRequiredForLevel(_ lvl: Int) -> Int {
        return 50 * lvl * (lvl - 1)
    }
    
    /// Progresso de XP dentro do nível atual (ex: 150 de 300 XP)
    var xpInCurrentLevel: Int {
        let currentLevelBase = xpRequiredForLevel(level)
        return xp - currentLevelBase
    }
    
    /// XP total necessário para passar do nível atual para o próximo
    var xpNeededForNextLevel: Int {
        let currentLevelBase = xpRequiredForLevel(level)
        let nextLevelBase = xpRequiredForLevel(level + 1)
        return nextLevelBase - currentLevelBase
    }
    
    /// Porcentagem de progresso para o próximo nível (0.0 a 1.0)
    var levelProgressFraction: Double {
        guard xpNeededForNextLevel > 0 else { return 1.0 }
        return min(1.0, Double(xpInCurrentLevel) / Double(xpNeededForNextLevel))
    }
    
    var streakDays: Int = 0
    var lastPracticeDate: Date? = nil
    var dailyGoalMinutes: Int = 15
    var todayPracticeMinutes: Int = 0
    
    // Conquistas (Engajamento de Curto, Médio e Longo Prazo)
    var badges: [Badge] = Badge.defaultBadges
}

struct Badge: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var description: String
    var iconName: String
    var category: String // "Iniciante", "Consistência", "Mestria", "Lendário"
    var isUnlocked: Bool
    
    static var defaultBadges: [Badge] {
        [
            // Nível 1: Curto Prazo (Primeiros Dias)
            Badge(id: "b1", title: "Primeiro Riff", description: "Tocou seu primeiro solo no app", iconName: "guitars.fill", category: "Iniciante", isUnlocked: true),
            Badge(id: "b2", title: "Chama Inicial", description: "Estudou por 3 dias seguidos", iconName: "flame.fill", category: "Consistência", isUnlocked: true),
            Badge(id: "b3", title: "Mestre da Lente", description: "Usou a função de desacelerar velocidade", iconName: "speedometer", category: "Mestria", isUnlocked: true),
            Badge(id: "b4", title: "Luthier Digital", description: "Criou seu primeiro riff personalizado", iconName: "music.note.list", category: "Iniciante", isUnlocked: false),
            
            // Nível 2: Médio Prazo (Semanas de Treino)
            Badge(id: "b5", title: "Semana Virtuosa", description: "Manteve 7 dias de ofensiva ininterruptos", iconName: "flame.circle.fill", category: "Consistência", isUnlocked: false),
            Badge(id: "b6", title: "Poliglota Musical", description: "Praticou faixas de 3 instrumentos diferentes", iconName: "pianokeys", category: "Mestria", isUnlocked: false),
            Badge(id: "b7", title: "Estudante Dedicado", description: "Acumulou 1.000 XP em sessões de estudo", iconName: "star.leadinghalf.filled", category: "Mestria", isUnlocked: false),
            Badge(id: "b8", title: "Colecionador", description: "Adicionou 5 solos à sua biblioteca", iconName: "folder.fill.badge.plus", category: "Iniciante", isUnlocked: false),
            
            // Nível 3: Avançado (Meses de Engajamento)
            Badge(id: "b9", title: "Hábito Inquebrável", description: "30 dias de ofensiva (1 mês direto!)", iconName: "calendar.badge.clock", category: "Consistência", isUnlocked: false),
            Badge(id: "b10", title: "Velocidade da Luz", description: "Tocou um solo difícil em 1.25x de velocidade", iconName: "bolt.fill", category: "Mestria", isUnlocked: false),
            Badge(id: "b11", title: "Maratonista Musical", description: "Acumulou 10 horas totais de treino ativo", iconName: "timer", category: "Mestria", isUnlocked: false),
            Badge(id: "b12", title: "Mestre do Metal", description: "Concluiu 25 sessões em BPM acima de 180", iconName: "waveform.path.badge.plus", category: "Mestria", isUnlocked: false),
            
            // Nível 4: LENDÁRIO (Meses a 1 Ano de Estudo Diário)
            Badge(id: "b13", title: "Centurião do Rock", description: "100 dias seguidos de estudo diário", iconName: "crown.fill", category: "Lendário", isUnlocked: false),
            Badge(id: "b14", title: "Shredder Supremo", description: "Alcançou o Nível 50 no aplicativo", iconName: "sparkles.tv.fill", category: "Lendário", isUnlocked: false),
            Badge(id: "b15", title: "Virtuoso Imortal", description: "365 dias de ofensiva - 1 ano inteiro de estudo!", iconName: "trophy.fill", category: "Lendário", isUnlocked: false),
            Badge(id: "b16", title: "Compositor Lendário", description: "Criou e publicou 25 riffs para a comunidade", iconName: "square.and.pencil", category: "Lendário", isUnlocked: false)
        ]
    }
}
