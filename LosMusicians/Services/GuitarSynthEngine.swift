import Foundation
import AVFoundation

/// Motor de síntese sonora nativo para reprodução de notas de violão, guitarra, baixo, bateria e metrônomo com precisão de estúdio
final class GuitarSynthEngine: ObservableObject {
    static let shared = GuitarSynthEngine()
    
    private var engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var isEngineRunning = false
    
    // Estado das cordas/vozes ativas com timbre
    private struct ActiveVoice {
        let frequency: Float
        var time: Float
        let sampleRate: Float
        var isPlucked: Bool
        let instrument: String // "guitar" | "acoustic" | "bass" | "drums" | "keys" | "metronome"
        let string: Int
        let volume: Float
    }
    
    private var activeVoices: [ActiveVoice] = []
    private let voiceLock = NSLock()
    
    // Configurações do Mixer Multitrack
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
    
    private init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        let sampleRate = Float(44100.0)
        
        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let buffer = ablPointer[0]
            guard let channelData = buffer.mData?.assumingMemoryBound(to: Float.self) else { return noErr }
            
            self.voiceLock.lock()
            for frame in 0..<Int(frameCount) {
                var sample: Float = 0.0
                
                for i in 0..<self.activeVoices.count {
                    let freq = self.activeVoices[i].frequency
                    let t = self.activeVoices[i].time
                    let inst = self.activeVoices[i].instrument
                    let string = self.activeVoices[i].string
                    let voiceVol = self.activeVoices[i].volume
                    
                    var voiceSample: Float = 0.0
                    
                    switch inst {
                    case "metronome":
                        // Metrônomo: clique curto percussivo
                        let click = sin(2.0 * .pi * freq * t) * exp(-t * 90.0)
                        voiceSample = click * 0.55 * voiceVol
                        
                    case "acoustic":
                        // Violão acústico: Karplus-Strong harmônico com decaimento natural e ruído de dedilhado
                        let fundamental = sin(2.0 * .pi * freq * t) * exp(-t * 2.2)
                        let harmonic2 = 0.45 * sin(2.0 * .pi * freq * 2.0 * t) * exp(-t * 3.5)
                        let harmonic3 = 0.2 * sin(2.0 * .pi * freq * 3.0 * t) * exp(-t * 5.0)
                        let harmonic4 = 0.08 * sin(2.0 * .pi * freq * 4.0 * t) * exp(-t * 7.0)
                        let pluckNoise = (Float.random(in: -1.0...1.0) * exp(-t * 100.0)) * 0.15
                        voiceSample = ((fundamental + harmonic2 + harmonic3 + harmonic4) * 0.45 + pluckNoise) * voiceVol
                        
                    case "bass":
                        // Baixo elétrico: 1 oitava abaixo (freq * 0.5), harmônicos cortados rapidamente para graves profundos
                        let bassFreq = freq * 0.5
                        let fundamental = sin(2.0 * .pi * bassFreq * t) * exp(-t * 2.5)
                        let harmonic2 = 0.35 * sin(2.0 * .pi * bassFreq * 2.0 * t) * exp(-t * 5.0)
                        let harmonic3 = 0.1 * sin(2.0 * .pi * bassFreq * 3.0 * t) * exp(-t * 8.0)
                        voiceSample = (fundamental + harmonic2 + harmonic3) * 0.75 * voiceVol
                        
                    case "drums":
                        // Bateria física sintética baseada na corda dedilhada
                        if string == 6 || string == 5 {
                            // Bumbo (Kick): seno com queda de frequência rápida e decay acentuado
                            let sweepFreq = max(42.0, 140.0 - t * 1200.0)
                            voiceSample = sin(2.0 * .pi * sweepFreq * t) * exp(-t * 18.0) * 0.85 * voiceVol
                        } else if string == 4 || string == 3 {
                            // Caixa (Snare): Ruído branco com envelope curto e tom de ressonância
                            let body = sin(2.0 * .pi * 175.0 * t) * exp(-t * 25.0)
                            let snareNoise = Float.random(in: -1.0...1.0) * exp(-t * 16.0)
                            voiceSample = (body * 0.35 + snareNoise * 0.65) * 0.65 * voiceVol
                        } else {
                            // Prato / Hi-hat: Ruído branco puro e curto
                            let hihatNoise = Float.random(in: -1.0...1.0) * exp(-t * 55.0)
                            voiceSample = hihatNoise * 0.25 * voiceVol
                        }
                        
                    case "keys":
                        // Teclado/Piano: Harmônicos ricos equilibrados com decay suave
                        let fundamental = sin(2.0 * .pi * freq * t) * exp(-t * 1.2)
                        let harmonic2 = 0.5 * sin(2.0 * .pi * freq * 2.0 * t) * exp(-t * 1.8)
                        let harmonic3 = 0.35 * sin(2.0 * .pi * freq * 3.0 * t) * exp(-t * 2.5)
                        let harmonic4 = 0.2 * sin(2.0 * .pi * freq * 4.0 * t) * exp(-t * 3.5)
                        let harmonic5 = 0.1 * sin(2.0 * .pi * freq * 5.0 * t) * exp(-t * 5.0)
                        voiceSample = (fundamental + harmonic2 + harmonic3 + harmonic4 + harmonic5) * 0.45 * voiceVol
                        
                    default:
                        // Guitarra Elétrica: Ondas ricas com saturação suave simulando overdrive
                        let fundamental = sin(2.0 * .pi * freq * t) * exp(-t * 1.5)
                        let harmonic2 = 0.62 * sin(2.0 * .pi * freq * 2.0 * t) * exp(-t * 2.2)
                        let harmonic3 = 0.42 * sin(2.0 * .pi * freq * 3.0 * t) * exp(-t * 3.0)
                        let harmonic4 = 0.25 * sin(2.0 * .pi * freq * 4.0 * t) * exp(-t * 4.5)
                        
                        let rawSound = (fundamental + harmonic2 + harmonic3 + harmonic4) * 0.5
                        let saturated = atan(rawSound * 2.5) / 1.5
                        voiceSample = saturated * voiceVol
                    }
                    
                    sample += voiceSample
                    self.activeVoices[i].time += 1.0 / sampleRate
                }
                
                // Remove vozes que já decaíram totalmente após 2 segundos
                self.activeVoices.removeAll { $0.time > 2.0 }
                
                channelData[frame] = max(-0.95, min(0.95, sample))
            }
            self.voiceLock.unlock()
            
            return noErr
        }
        
        self.sourceNode = node
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1)!
        
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        
        startEngineIfNeeded()
    }
    
    func startEngineIfNeeded() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP, .mixWithOthers]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            if !engine.isRunning {
                engine.prepare()
                try engine.start()
                isEngineRunning = true
            }
        } catch {
            print("⚠️ Erro ao iniciar AVAudioEngine de síntese:", error)
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
    
    // MARK: - Controles do Mixer Multitrack (Mute, Solo, Volume)
    
    func setVolume(for instrument: String, volume: Float) {
        let key = normalizeInstrument(instrument)
        voiceLock.lock()
        instrumentVolumes[key] = max(0.0, min(1.0, volume))
        voiceLock.unlock()
    }
    
    func getVolume(for instrument: String) -> Float {
        let key = normalizeInstrument(instrument)
        return instrumentVolumes[key] ?? 1.0
    }
    
    func setMuted(for instrument: String, isMuted: Bool) {
        let key = normalizeInstrument(instrument)
        voiceLock.lock()
        if isMuted {
            mutedInstruments.insert(key)
        } else {
            mutedInstruments.remove(key)
        }
        voiceLock.unlock()
    }
    
    func isMuted(instrument: String) -> Bool {
        let key = normalizeInstrument(instrument)
        return mutedInstruments.contains(key)
    }
    
    func setSolo(for instrument: String?, isSolo: Bool) {
        voiceLock.lock()
        if let inst = instrument, isSolo {
            soloInstrument = normalizeInstrument(inst)
        } else {
            soloInstrument = nil
        }
        voiceLock.unlock()
    }
    
    func isSolo(instrument: String) -> Bool {
        let key = normalizeInstrument(instrument)
        return soloInstrument == key
    }
    
    private func effectiveVolume(for instrument: String) -> Float {
        let key = normalizeInstrument(instrument)
        if key == "metronome" { return 1.0 }
        
        // Se houver Solo ativo e não for este instrumento, silencia
        if let solo = soloInstrument, solo != key {
            return 0.0
        }
        
        // Se estiver mutado, volume zero
        if mutedInstruments.contains(key) {
            return 0.0
        }
        
        return instrumentVolumes[key] ?? 1.0
    }
    
    // MARK: - Reprodução Musical
    
    /// Toca uma nota por número MIDI aplicando transposição de semitons (Pitch Shift)
    func playNote(midi: Int, instrument: String = "Guitarra", string: Int = 1, pitchShift: Int? = nil) {
        let normalized = normalizeInstrument(instrument)
        let vol = effectiveVolume(for: normalized)
        guard vol > 0.001 else { return } // Ignora notas se o instrumento estiver mutado
        
        startEngineIfNeeded()
        
        let effectiveShift = pitchShift ?? pitchShiftSemitones
        let transposedMidi = midi + effectiveShift
        let freq = 440.0 * pow(2.0, Float(transposedMidi - 69) / 12.0)
        
        voiceLock.lock()
        if activeVoices.count > 8 {
            activeVoices.removeFirst()
        }
        activeVoices.append(ActiveVoice(
            frequency: freq,
            time: 0.0,
            sampleRate: 44100.0,
            isPlucked: true,
            instrument: normalized,
            string: string,
            volume: vol
        ))
        voiceLock.unlock()
    }
    
    /// Toca nota por corda (1 a 6) e casa (fret) com pitch shift
    func playFret(string: Int, fret: Int, instrument: String = "Guitarra", pitchShift: Int? = nil) {
        let openMidiByString: [Int: Int] = [
            6: 40,
            5: 45,
            4: 50,
            3: 55,
            2: 59,
            1: 64
        ]
        
        let baseMidi = openMidiByString[string] ?? 40
        let midi = baseMidi + fret
        playNote(midi: midi, instrument: instrument, string: string, pitchShift: pitchShift)
    }
    
    /// Toca um clique de metrônomo ou contagem regressiva (Count-In)
    func playMetronomeTick(isStrong: Bool) {
        startEngineIfNeeded()
        let freq: Float = isStrong ? 1050.0 : 700.0
        voiceLock.lock()
        if activeVoices.count > 8 {
            activeVoices.removeFirst()
        }
        activeVoices.append(ActiveVoice(
            frequency: freq,
            time: 0.0,
            sampleRate: 44100.0,
            isPlucked: true,
            instrument: "metronome",
            string: 1,
            volume: 1.0
        ))
        voiceLock.unlock()
    }
    
    /// Toca um clique específico de Count-In (1, 2, 3, 4)
    func playCountInTick(beat: Int, totalBeats: Int = 4) {
        startEngineIfNeeded()
        let isFirstBeat = (beat == 1)
        let freq: Float = isFirstBeat ? 1250.0 : (beat == totalBeats ? 950.0 : 750.0)
        
        voiceLock.lock()
        if activeVoices.count > 8 {
            activeVoices.removeFirst()
        }
        activeVoices.append(ActiveVoice(
            frequency: freq,
            time: 0.0,
            sampleRate: 44100.0,
            isPlucked: true,
            instrument: "metronome",
            string: 1,
            volume: 1.2
        ))
        voiceLock.unlock()
    }
    
    /// Para todas as vozes ativas imediatamente
    func stopAll() {
        voiceLock.lock()
        activeVoices.removeAll()
        voiceLock.unlock()
    }
}
