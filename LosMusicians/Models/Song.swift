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
    var tabDataJson: String? // Dados da tablatura (AlphaTab / MusicXML / GP)
    
    static var sampleSongs: [Song] = [
        Song(
            id: "s1",
            title: "Master of Puppets (Solo)",
            artist: "Metallica",
            difficulty: "Insano",
            bpm: 212,
            tracks: [
                InstrumentTrack(id: "t1", name: "Guitarra Solo (Kirk Hammett)", instrument: .leadGuitar),
                InstrumentTrack(id: "t2", name: "Guitarra Base (James Hetfield)", instrument: .rhythmGuitar),
                InstrumentTrack(id: "t3", name: "Baixo (Cliff Burton)", instrument: .bass)
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
                InstrumentTrack(id: "t4", name: "Guitarra Solo (Slash)", instrument: .leadGuitar),
                InstrumentTrack(id: "t5", name: "Guitarra Base (Izzy Stradlin)", instrument: .rhythmGuitar),
                InstrumentTrack(id: "t6", name: "Baixo (Duff McKagan)", instrument: .bass)
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
                InstrumentTrack(id: "t7", name: "Minha Guitarra", instrument: .leadGuitar)
            ],
            isPublic: false,
            authorName: "Você"
        )
    ]
}
