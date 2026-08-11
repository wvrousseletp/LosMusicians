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
            
            self.voiceLock.lock()
            
            // Se não houver vozes ativas, zera os buffers para evitar chiado de hardware e poupar CPU
            if self.activeVoices.isEmpty {
                for buffer in ablPointer {
                    if let channelData = buffer.mData {
                        memset(channelData, 0, Int(frameCount) * MemoryLayout<Float>.stride)
                    }
                }
                self.voiceLock.unlock()
                return noErr
            }
            
            var localSamples = [Float](repeating: 0.0, count: Int(frameCount))
            let frameDuration = 1.0 / sampleRate
            
            // Renderiza cada frame
            for frame in 0..<Int(frameCount) {
                var frameSample: Float = 0.0
                
                for i in 0..<self.activeVoices.count {
                    let freq = self.activeVoices[i].frequency
                    let t = self.activeVoices[i].time
                    let inst = self.activeVoices[i].instrument
                    let string = self.activeVoices[i].string
                    let voiceVol = self.activeVoices[i].volume
                    
                    var voiceSample: Float = 0.0
                    
                    voiceSample = self.computeSample(freq: freq, t: t, inst: inst, string: string, voiceVol: voiceVol)
                    
                    frameSample += voiceSample
                    // Atualiza o tempo na própria iteração
                    self.activeVoices[i].time += frameDuration
                }
                
                // Hard clipper mix para evitar estouros (distorção digital)
                localSamples[frame] = max(-0.95, min(0.95, frameSample))
            }
            
            // Remove as notas expiradas (< 2.5s) apenas UMA VEZ por bloco, fora do loop de frame
            self.activeVoices.removeAll { $0.time > 2.5 }
            
            self.voiceLock.unlock()
            
            // Escreve os samples calculados em TODOS os canais solicitados (Esquerdo, Direito, etc.)
            for buffer in ablPointer {
                if let channelData = buffer.mData?.assumingMemoryBound(to: Float.self) {
                    for frame in 0..<Int(frameCount) {
                        channelData[frame] = localSamples[frame]
                    }
                }
            }
            
            return noErr
        }
        
        self.sourceNode = node
        // Solicitando formato estéreo padrão
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 2)!
        
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        
        engine.mainMixerNode.outputVolume = 1.0
        
        startEngineIfNeeded()
    }
    
    @inline(__always)
    private func computeSample(freq: Float, t: Float, inst: String, string: Int, voiceVol: Float) -> Float {
        switch inst {
        case "metronome":
            let click = sin(2.0 * .pi * freq * t) * exp(-t * 90.0)
            return click * 0.85 * voiceVol
            
        case "acoustic":
            let fundamental = sin(2.0 * .pi * freq * t) * exp(-t * 2.5)
            let harmonic2 = 0.6 * sin(2.0 * .pi * freq * 2.0 * t) * exp(-t * 3.5)
            let harmonic3 = 0.3 * sin(2.0 * .pi * freq * 3.0 * t) * exp(-t * 5.0)
            let harmonic4 = 0.15 * sin(2.0 * .pi * freq * 4.0 * t) * exp(-t * 7.0)
            let pluckNoise = (Float.random(in: -1.0...1.0) * exp(-t * 150.0)) * 0.25
            return ((fundamental + harmonic2 + harmonic3 + harmonic4) * 0.55 + pluckNoise) * voiceVol
            
        case "bass":
            let bassFreq = freq * 0.5
            let fundamental = sin(2.0 * .pi * bassFreq * t) * exp(-t * 3.0)
            let harmonic2 = 0.5 * sin(2.0 * .pi * bassFreq * 2.0 * t) * exp(-t * 5.0)
            let harmonic3 = 0.15 * sin(2.0 * .pi * bassFreq * 3.0 * t) * exp(-t * 8.0)
            return (fundamental + harmonic2 + harmonic3) * 0.95 * voiceVol
            
        case "drums":
            if string == 6 || string == 5 {
                let sweepFreq = max(40.0, 150.0 - t * 1400.0)
                return sin(2.0 * .pi * sweepFreq * t) * exp(-t * 18.0) * 0.95 * voiceVol
            } else if string == 4 || string == 3 {
                let body = sin(2.0 * .pi * 180.0 * t) * exp(-t * 30.0)
                let snareNoise = Float.random(in: -1.0...1.0) * exp(-t * 18.0)
                return (body * 0.4 + snareNoise * 0.7) * 0.8 * voiceVol
            } else {
                let hihatNoise = Float.random(in: -1.0...1.0) * exp(-t * 60.0)
                return hihatNoise * 0.45 * voiceVol
            }
            
        case "keys":
            let fundamental = sin(2.0 * .pi * freq * t) * exp(-t * 1.5)
            let harmonic2 = 0.55 * sin(2.0 * .pi * freq * 2.0 * t) * exp(-t * 2.0)
            let harmonic3 = 0.4 * sin(2.0 * .pi * freq * 3.0 * t) * exp(-t * 3.0)
            let harmonic4 = 0.25 * sin(2.0 * .pi * freq * 4.0 * t) * exp(-t * 4.0)
            let harmonic5 = 0.15 * sin(2.0 * .pi * freq * 5.0 * t) * exp(-t * 6.0)
            return (fundamental + harmonic2 + harmonic3 + harmonic4 + harmonic5) * 0.5 * voiceVol
            
        default:
            let fundamental = sin(2.0 * .pi * freq * t) * exp(-t * 1.8)
            let harmonic2 = 0.65 * sin(2.0 * .pi * freq * 2.0 * t) * exp(-t * 2.5)
            let harmonic3 = 0.45 * sin(2.0 * .pi * freq * 3.0 * t) * exp(-t * 3.5)
            let harmonic4 = 0.3 * sin(2.0 * .pi * freq * 4.0 * t) * exp(-t * 5.0)
            let rawSound = (fundamental + harmonic2 + harmonic3 + harmonic4) * 0.55
            return (atan(rawSound * 3.0) / 1.5) * voiceVol
        }
    }
    
    func startEngineIfNeeded() {
        do {
            let session = AVAudioSession.sharedInstance()
            // IMPORTANTE: .playback ignora a chave de silencioso/vibrar do iPhone!
            // .mixWithOthers permite tocar som junto com outros apps (Spotify em background, etc)
            // Removidas opções bluetooth pois elas podiam falhar silenciosamente no AVAudioSession e impedir o AudioEngine de ligar
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try session.setActive(true)
            
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
        if activeVoices.count > 12 {
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
        if activeVoices.count > 12 {
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
        if activeVoices.count > 12 {
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
