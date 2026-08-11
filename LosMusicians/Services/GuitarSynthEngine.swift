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
        let omega = 2.0 * Float.pi * freq
        
        switch inst {
        case "metronome":
            let click = sin(omega * t) * exp(-t * 120.0)
            return click * 0.8 * voiceVol
            
        case "acoustic":
            // Violão de Aço/Nylon: Ataque de palheta suave + ressonância de caixa de madeira
            let f1 = sin(omega * t) * exp(-t * 2.2)
            let f2 = 0.55 * sin(omega * 2.0 * t) * exp(-t * 3.2)
            let f3 = 0.28 * sin(omega * 3.0 * t) * exp(-t * 4.5)
            let f4 = 0.12 * sin(omega * 4.0 * t) * exp(-t * 6.5)
            let pluckNoise = (Float.random(in: -0.6...0.6) * exp(-t * 180.0)) * 0.15
            let bodyResonance = sin(2.0 * Float.pi * 110.0 * t) * exp(-t * 5.0) * 0.08
            let rawAcoustic = (f1 + f2 + f3 + f4) * 0.5 + pluckNoise + bodyResonance
            return rawAcoustic * voiceVol
            
        case "bass":
            // Contrabaixo Elétrico: Sub-grave profundo + punch de ataque + harmônicos quentes
            let bassFreq = freq * 0.5
            let bOmega = 2.0 * Float.pi * bassFreq
            let sub = sin(bOmega * t) * exp(-t * 2.0)
            let h2 = 0.6 * sin(bOmega * 2.0 * t) * exp(-t * 3.8)
            let h3 = 0.25 * sin(bOmega * 3.0 * t) * exp(-t * 6.0)
            let pluckAttack = sin(bOmega * 4.0 * t) * exp(-t * 25.0) * 0.2
            let rawBass = (sub * 1.1 + h2 + h3 + pluckAttack) * 0.55
            return tanh(rawBass * 1.4) * voiceVol
            
        case "drums":
            // Bateria Física Sintetizada
            if string == 6 || string == 5 {
                // Bumbo (Kick): Sweep de frequência grave (160Hz -> 45Hz) + Thump
                let kickSweep = max(45.0, 160.0 - t * 1500.0)
                let kickBody = sin(2.0 * Float.pi * kickSweep * t) * exp(-t * 16.0)
                let kickClick = (Float.random(in: -0.8...0.8) * exp(-t * 120.0)) * 0.2
                return (kickBody + kickClick) * 0.95 * voiceVol
            } else if string == 4 || string == 3 {
                // Caixa (Snare): Corpo em 180Hz + Ruído de Esteira Metálica
                let snareBody = sin(2.0 * Float.pi * 180.0 * t) * exp(-t * 28.0)
                let snareWireNoise = Float.random(in: -1.0...1.0) * exp(-t * 16.0)
                return (snareBody * 0.45 + snareWireNoise * 0.65) * 0.85 * voiceVol
            } else {
                // Prato/Chimbal (Hi-Hat): Ruído de alta frequência filtrado + ataque rápido
                let hihatNoise = Float.random(in: -1.0...1.0) * exp(-t * 70.0)
                let metallicRing = sin(2.0 * Float.pi * 7500.0 * t) * exp(-t * 80.0) * 0.3
                return (hihatNoise + metallicRing) * 0.45 * voiceVol
            }
            
        case "keys":
            // Teclado/Piano de Cauda: Série harmônica natural com decaimento duplo
            let p1 = sin(omega * t) * exp(-t * 1.8)
            let p2 = 0.5 * sin(omega * 2.0 * t) * exp(-t * 2.2)
            let p3 = 0.35 * sin(omega * 3.0 * t) * exp(-t * 3.0)
            let p4 = 0.2 * sin(omega * 4.0 * t) * exp(-t * 4.2)
            let p5 = 0.1 * sin(omega * 5.0 * t) * exp(-t * 6.0)
            return (p1 + p2 + p3 + p4 + p5) * 0.45 * voiceVol
            
        default:
            // Guitarra Elétrica Solista/Base: Harmônicos ricos + simulador de amplificador a válvula (Tube Overdrive)
            let g1 = sin(omega * t) * exp(-t * 2.0)
            let g2 = 0.7 * sin(omega * 2.0 * t) * exp(-t * 2.8)
            let g3 = 0.45 * sin(omega * 3.0 * t) * exp(-t * 4.0)
            let g4 = 0.25 * sin(omega * 4.0 * t) * exp(-t * 5.5)
            let g5 = 0.15 * sin(omega * 5.0 * t) * exp(-t * 7.5)
            let pickAttack = (Float.random(in: -0.5...0.5) * exp(-t * 200.0)) * 0.15
            let rawGuitar = (g1 + g2 + g3 + g4 + g5) * 0.6 + pickAttack
            
            // Saturação válvula suave (Soft-clipping Tube Amp curve)
            let tubeOverdrive = tanh(rawGuitar * 2.2) / 1.15
            return tubeOverdrive * voiceVol
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
