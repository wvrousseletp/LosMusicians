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
    var tabDataJson: String? // AlphaTex fallback
    
    static var sampleSongs: [Song] = [
        
        // 1. Master of Puppets — Metallica
        Song(
            id: "s1",
            title: "Master of Puppets (Riff Principal)",
            artist: "Metallica",
            difficulty: "Insano",
            bpm: 212,
            tracks: [
                InstrumentTrack(id: "t1a", name: "Guitarra Solo (Kirk Hammett)", instrument: .leadGuitar,
                    tabDataJson: ":16 12.1 15.1 14.2 12.1 15.1 14.2 12.1 15.1 | 14.1 17.1 15.2 14.1 17.1 15.2 14.1 17.1 | 12.1 15.1 14.2 12.1 10.1 12.1 14.1 15.1 | 17.1 15.1 14.1 12.1 10.1 9.1 7.1 5.1"),
                InstrumentTrack(id: "t1b", name: "Guitarra Base (James Hetfield)", instrument: .rhythmGuitar,
                    tabDataJson: ":8 0.6 0.6 2.6 0.6 3.6 0.6 2.6 0.6 | 0.6 0.6 2.6 0.6 3.6 0.6 2.6 0.6 | 5.6 5.6 5.6 5.6 3.6 3.6 2.6 2.6 | 0.6 0.6 0.6 0.6 0.6 0.6 0.6 0.6"),
                InstrumentTrack(id: "t1c", name: "Baixo (Cliff Burton)", instrument: .bass,
                    tabDataJson: ":8 0.4 0.4 2.4 0.4 3.4 0.4 2.4 0.4 | 0.4 0.4 2.4 0.4 3.4 0.4 2.4 0.4")
            ],
            isPublic: true,
            authorName: "LosMusicians Official"
        ),
        
        // 2. Sweet Child O' Mine — Guns N' Roses
        Song(
            id: "s2",
            title: "Sweet Child O' Mine (Intro Riff)",
            artist: "Guns N' Roses",
            difficulty: "Médio",
            bpm: 125,
            tracks: [
                InstrumentTrack(id: "t2a", name: "Guitarra (Slash)", instrument: .leadGuitar,
                    tabDataJson: ":8 12.4 15.2 14.3 12.3 15.1 14.3 14.1 14.3 | 12.4 15.2 14.3 12.3 15.1 14.3 14.1 14.3 | 12.5 14.3 14.2 12.3 14.1 12.3 14.2 14.3 | 14.4 12.4 14.3 12.3 14.2 12.2 14.1 12.1"),
                InstrumentTrack(id: "t2b", name: "Guitarra Base (Izzy)", instrument: .rhythmGuitar,
                    tabDataJson: ":4 0.5 0.5 0.5 0.5 | 3.5 3.5 3.5 3.5 | 5.5 5.5 5.5 5.5 | 2.5 2.5 2.5 2.5"),
                InstrumentTrack(id: "t2c", name: "Baixo (Duff)", instrument: .bass,
                    tabDataJson: ":4 0.3 0.3 0.3 0.3 | 3.3 3.3 3.3 3.3")
            ],
            isPublic: true,
            authorName: "LosMusicians Official"
        ),
        
        // 3. Smoke on the Water — Deep Purple
        Song(
            id: "s3",
            title: "Smoke on the Water (Riff Clássico)",
            artist: "Deep Purple",
            difficulty: "Fácil",
            bpm: 112,
            tracks: [
                InstrumentTrack(id: "t3a", name: "Guitarra (Ritchie Blackmore)", instrument: .leadGuitar,
                    tabDataJson: ":4 0.6 3.6 5.6 | 0.6 3.6 6.6 5.6 | 0.6 3.6 5.6 | 3.6 0.6"),
                InstrumentTrack(id: "t3b", name: "Baixo (Roger Glover)", instrument: .bass,
                    tabDataJson: ":4 0.4 0.4 3.4 5.4 | 0.4 0.4 3.4 6.4 | 0.4 0.4 3.4 5.4 | 3.4 0.4")
            ],
            isPublic: true,
            authorName: "LosMusicians Official"
        ),
        
        // 4. Back in Black — AC/DC
        Song(
            id: "s4",
            title: "Back in Black (Riff de Abertura)",
            artist: "AC/DC",
            difficulty: "Fácil",
            bpm: 96,
            tracks: [
                InstrumentTrack(id: "t4a", name: "Guitarra (Angus Young)", instrument: .leadGuitar,
                    tabDataJson: ":8 0.5 0.5 3.5 0.5 | 2.5 0.5 2.5 3.5 | 0.5 0.5 3.5 0.5 | 2.5 0.5 2.5 3.5 | :4 0.6 2.6 3.6 5.6"),
                InstrumentTrack(id: "t4b", name: "Baixo (Cliff Williams)", instrument: .bass,
                    tabDataJson: ":8 0.3 0.3 3.3 0.3 | 2.3 0.3 2.3 3.3 | 0.3 0.3 3.3 0.3 | 2.3 0.3 2.3 3.3")
            ],
            isPublic: true,
            authorName: "LosMusicians Official"
        ),
        
        // 5. Seven Nation Army — The White Stripes
        Song(
            id: "s5",
            title: "Seven Nation Army (Riff Principal)",
            artist: "The White Stripes",
            difficulty: "Fácil",
            bpm: 124,
            tracks: [
                InstrumentTrack(id: "t5a", name: "Guitarra/Baixo (Jack White)", instrument: .leadGuitar,
                    tabDataJson: ":4 7.5 7.5 10.5 7.5 5.5 3.5 2.5 | 7.5 7.5 10.5 7.5 5.5 3.5 2.5 | 7.5 7.5 10.5 7.5 5.5 3.5 | 5.5 3.5 2.5 0.5")
            ],
            isPublic: true,
            authorName: "LosMusicians Official"
        ),
        
        // 6. Come as You Are — Nirvana
        Song(
            id: "s6",
            title: "Come as You Are (Riff de Intro)",
            artist: "Nirvana",
            difficulty: "Fácil",
            bpm: 120,
            tracks: [
                InstrumentTrack(id: "t6a", name: "Guitarra (Kurt Cobain)", instrument: .leadGuitar,
                    tabDataJson: ":8 0.5 2.5 2.5 0.5 2.5 0.5 3.5 0.5 | 0.5 2.5 2.5 0.5 2.5 3.5 2.5 0.5 | 0.6 2.6 2.6 0.6 2.6 0.6 3.6 0.6 | 0.6 2.6 2.6 0.6 2.6 3.6 2.6 0.6"),
                InstrumentTrack(id: "t6b", name: "Baixo (Krist Novoselic)", instrument: .bass,
                    tabDataJson: ":4 0.3 0.3 2.3 3.3 | 0.3 0.3 2.3 3.3")
            ],
            isPublic: true,
            authorName: "LosMusicians Official"
        ),
        
        // 7. Wish You Were Here — Pink Floyd
        Song(
            id: "s7",
            title: "Wish You Were Here (Intro Fingerstyle)",
            artist: "Pink Floyd",
            difficulty: "Médio",
            bpm: 66,
            tracks: [
                InstrumentTrack(id: "t7a", name: "Violão (David Gilmour)", instrument: .rhythmGuitar,
                    tabDataJson: ":8 0.5 2.4 0.4 2.3 0.3 2.2 0.2 2.1 | 0.5 2.4 0.4 2.3 0.3 0.2 2.1 0.1 | 3.5 0.4 2.4 0.3 2.3 0.2 3.2 0.1 | 0.5 2.4 3.4 0.3 2.3 0.2 0.1 0.1")
            ],
            isPublic: true,
            authorName: "LosMusicians Official"
        ),
        
        // 8. Meu Riff de Treino (Exemplo do Usuário)
        Song(
            id: "s8",
            title: "Meu Riff de Treino Metal",
            artist: "Você",
            difficulty: "Fácil",
            bpm: 140,
            tracks: [
                InstrumentTrack(id: "t8a", name: "Minha Guitarra", instrument: .leadGuitar,
                    tabDataJson: ":8 5.6 7.6 8.6 7.6 5.5 7.5 8.5 7.5 | 5.4 7.4 8.4 7.4 5.3 7.3 8.3 7.3 | 5.2 7.2 8.2 7.2 5.1 7.1 8.1 7.1 | 8.1 7.1 5.1 7.1 8.2 7.2 5.2 7.2")
            ],
            isPublic: false,
            authorName: "Você"
        )
    ]
}
