import Foundation
import AVFoundation

/// Motor de síntese sonora nativo para reprodução de notas de violão, guitarra, baixo, bateria e metrônomo com precisão de estúdio
final class GuitarSynthEngine: ObservableObject {
    static let shared = GuitarSynthEngine()
    
    private var engine = AVAudioEngine()
    private var midiSynth = AVAudioUnitMIDISynth()
    private var isEngineRunning = false
    
    @Published var pitchShiftSemitones: Int = 0
    private var instrumentVolumes: [String: Float] = [
        "guitar": 1.0,
        "acoustic": 1.0,
        "bass": 1.0,
        "drums": 1.0,
        "keys": 1.0,
        "metronome": 1.0
    ]
    private var mutedInstruments: Set<String> = []
    private var soloInstrument: String? = nil
    
    // MIDI Channels for different instruments
    private let channels: [String: UInt8] = [
        "acoustic": 0,
        "guitar": 1,
        "bass": 2,
        "keys": 3,
        "metronome": 4,
        "drums": 9 // MIDI Channel 10 (0-indexed 9) is standard for drums
    ]
    
    private init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        engine.attach(midiSynth)
        engine.connect(midiSynth, to: engine.mainMixerNode, format: nil)
        
        startEngineIfNeeded()
        
        // Setup initial MIDI programs
        // 25 = Acoustic Guitar (Nylon/Steel)
        midiSynth.sendProgramChange(25, onChannel: channels["acoustic"]!)
        // 27 = Electric Guitar (Clean), or 29 (Overdriven)
        midiSynth.sendProgramChange(29, onChannel: channels["guitar"]!)
        // 33 = Electric Bass (Finger)
        midiSynth.sendProgramChange(33, onChannel: channels["bass"]!)
        // 0 = Acoustic Grand Piano
        midiSynth.sendProgramChange(0, onChannel: channels["keys"]!)
        // Metronome can use a woodblock (115)
        midiSynth.sendProgramChange(115, onChannel: channels["metronome"]!)
        
        // Drums channel automatically uses drum kits on channel 9
    }
    
    func startEngineIfNeeded() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            
            if !engine.isRunning {
                engine.prepare()
                try engine.start()
                isEngineRunning = true
            }
        } catch {
            print("⚠️ Erro ao iniciar AVAudioEngine:", error)
        }
    }
    
    func normalizeInstrument(_ instrument: String) -> String {
        let lower = instrument.lowercased()
        if lower.contains("violão") || lower.contains("acoustic") {
            return "acoustic"
        } else if lower.contains("baixo") || lower.contains("bass") {
            return "bass"
        } else if lower.contains("bateria") || lower.contains("drum") || lower.contains("drums") {
            return "drums"
        } else if lower.contains("teclado") || lower.contains("piano") || lower.contains("keys") || lower.contains("keyboard") {
            return "keys"
        } else if lower.contains("metronomo") || lower.contains("metronome") {
            return "metronome"
        } else {
            return "guitar"
        }
    }
    
    // MARK: - Controles do Mixer Multitrack
    
    func setVolume(for instrument: String, volume: Float) {
        let key = normalizeInstrument(instrument)
        instrumentVolumes[key] = max(0.0, min(1.0, volume))
        // MIDI volume control (CC 7) is 0-127
        let midiVol = UInt8(instrumentVolumes[key]! * 127.0)
        if let ch = channels[key] {
            midiSynth.sendController(7, withValue: midiVol, onChannel: ch)
        }
    }
    
    func getVolume(for instrument: String) -> Float {
        let key = normalizeInstrument(instrument)
        return instrumentVolumes[key] ?? 1.0
    }
    
    func setMuted(for instrument: String, isMuted: Bool) {
        let key = normalizeInstrument(instrument)
        if isMuted {
            mutedInstruments.insert(key)
        } else {
            mutedInstruments.remove(key)
        }
    }
    
    func isMuted(instrument: String) -> Bool {
        return mutedInstruments.contains(normalizeInstrument(instrument))
    }
    
    func setSolo(for instrument: String?, isSolo: Bool) {
        if let inst = instrument, isSolo {
            soloInstrument = normalizeInstrument(inst)
        } else {
            soloInstrument = nil
        }
    }
    
    func isSolo(instrument: String) -> Bool {
        return soloInstrument == normalizeInstrument(instrument)
    }
    
    private func effectiveVolume(for instrument: String) -> Float {
        let key = normalizeInstrument(instrument)
        if key == "metronome" { return 1.0 }
        
        if let solo = soloInstrument, solo != key {
            return 0.0
        }
        if mutedInstruments.contains(key) {
            return 0.0
        }
        return instrumentVolumes[key] ?? 1.0
    }
    
    // MARK: - Reprodução Musical
    
    func playNote(midi: Int, instrument: String = "Guitarra", string: Int = 1, pitchShift: Int? = nil) {
        let normalized = normalizeInstrument(instrument)
        let vol = effectiveVolume(for: normalized)
        guard vol > 0.001 else { return }
        
        startEngineIfNeeded()
        
        let effectiveShift = pitchShift ?? pitchShiftSemitones
        var transposedMidi = midi + effectiveShift
        
        // Ensure midi is within bounds 0-127
        transposedMidi = max(0, min(127, transposedMidi))
        
        if let ch = channels[normalized] {
            let velocity = UInt8(vol * 100.0) // slightly lower than 127 to avoid clipping
            midiSynth.sendNoteOn(UInt8(transposedMidi), withVelocity: velocity, onChannel: ch)
            
            // Auto stop note after a certain time to prevent hanging notes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.midiSynth.sendNoteOff(UInt8(transposedMidi), withVelocity: 0, onChannel: ch)
            }
        }
    }
    
    func playFret(string: Int, fret: Int, instrument: String = "Guitarra", pitchShift: Int? = nil) {
        let openMidiByString: [Int: Int] = [
            6: 40, 5: 45, 4: 50, 3: 55, 2: 59, 1: 64
        ]
        let baseMidi = openMidiByString[string] ?? 40
        playNote(midi: baseMidi + fret, instrument: instrument, string: string, pitchShift: pitchShift)
    }
    
    func playMetronomeTick(isStrong: Bool) {
        startEngineIfNeeded()
        guard let ch = channels["metronome"] else { return }
        
        let note: UInt8 = isStrong ? 76 : 77 // Woodblock High/Low
        midiSynth.sendNoteOn(note, withVelocity: 110, onChannel: ch)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.midiSynth.sendNoteOff(note, withVelocity: 0, onChannel: ch)
        }
    }
    
    func playCountInTick(beat: Int, totalBeats: Int = 4) {
        let isStrong = (beat == 1)
        playMetronomeTick(isStrong: isStrong)
    }
    
    func stopAll() {
        // Send All Notes Off (CC 123) for each channel
        for (_, ch) in channels {
            midiSynth.sendController(123, withValue: 0, onChannel: ch)
        }
    }
}
