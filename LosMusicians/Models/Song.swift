import Foundation

enum InstrumentType: String, CaseIterable, Codable, Identifiable {
    case leadGuitar = "Guitarra Solo"
    case rhythmGuitar = "Guitarra Base"
    case bass = "Baixo"
    case drums = "Bateria"
    case keys = "Teclado"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .leadGuitar, .rhythmGuitar: return "guitars"
        case .bass: return "waveform.path"
        case .drums: return "filemenu.and.selection"
        case .keys: return "piano"
        }
    }
}

struct InstrumentTrack: Identifiable, Codable {
    var id: String
    var name: String
    var instrument: InstrumentType
    var tuning: String = "E Standard"
    var tabDataJson: String?
}

struct Song: Identifiable, Codable {
    var id: String
    var title: String
    var artist: String
    var coverUrl: String?
    var difficulty: String // "Fácil", "Médio", "Difícil", "Insano"
    var bpm: Int
    var tracks: [InstrumentTrack]
    var isPublic: Bool
    var authorName: String
    var tabDataJson: String? // Fallback data
    
    static var sampleSongs: [Song] = [
        Song(
            id: "s1",
            title: "Master of Puppets (Solo)",
            artist: "Metallica",
            difficulty: "Insano",
            bpm: 212,
            tracks: [
                InstrumentTrack(id: "t1", name: "Guitarra Solo (Kirk Hammett)", instrument: .leadGuitar, tabDataJson: ":16 12.1 15.1 14.2 12.1 15.1 14.2 12.1 15.1 | 14.1 17.1 15.2 14.1 17.1 15.2 14.1 17.1"),
                InstrumentTrack(id: "t2", name: "Guitarra Base (James Hetfield)", instrument: .rhythmGuitar, tabDataJson: ":8 0.6 0.6 0.6 0.6 0.6 0.6 0.6 0.6 | :4 2.5 3.5 4.5 5.5"),
                InstrumentTrack(id: "t3", name: "Baixo (Cliff Burton)", instrument: .bass, tabDataJson: ":8 0.4 0.4 0.4 0.4 0.4 0.4 0.4 0.4 | :4 2.3 3.3 4.3 5.3")
            ],
            isPublic: true,
            authorName: "LosMusicians Official"
        ),
        Song(
            id: "s2",
            title: "Sweet Child O' Mine (Intro Riff)",
            artist: "Guns N' Roses",
            difficulty: "Médio",
            bpm: 125,
            tracks: [
                InstrumentTrack(id: "t4", name: "Guitarra Solo (Slash)", instrument: .leadGuitar, tabDataJson: ":8 12.4 15.2 14.3 12.3 15.1 14.3 14.1 14.3 | 12.4 15.2 14.3 12.3 15.1 14.3 14.1 14.3"),
                InstrumentTrack(id: "t5", name: "Guitarra Base (Izzy Stradlin)", instrument: .rhythmGuitar, tabDataJson: ":4 0.5 0.5 0.5 0.5 | 3.5 3.5 3.5 3.5"),
                InstrumentTrack(id: "t6", name: "Baixo (Duff McKagan)", instrument: .bass, tabDataJson: ":4 0.3 0.3 0.3 0.3 | 3.3 3.3 3.3 3.3")
            ],
            isPublic: true,
            authorName: "LosMusicians Official"
        ),
        Song(
            id: "s3",
            title: "Meu Riff de Treino Metal",
            artist: "Você",
            difficulty: "Fácil",
            bpm: 140,
            tracks: [
                InstrumentTrack(id: "t7", name: "Minha Guitarra", instrument: .leadGuitar, tabDataJson: ":8 5.6 7.6 8.6 7.6 5.5 7.5 8.5 7.5 | 5.4 7.4 8.4 7.4 5.3 7.3 8.3 7.3")
            ],
            isPublic: false,
            authorName: "Você"
        )
    ]
}
