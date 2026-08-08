import Foundation
import AVFoundation

/// Motor de síntese sonora nativo para reprodução de notas de violão e guitarra com precisão de estúdio
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
    }
    
    private var activeVoices: [ActiveVoice] = []
    private let voiceLock = NSLock()
    
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
                    
                    var voiceSample: Float = 0.0
                    
                    switch inst {
                    case "metronome":
                        // Metrônomo: clique curto percussivo
                        let click = sin(2.0 * .pi * freq * t) * exp(-t * 90.0)
                        voiceSample = click * 0.45
                        
                    case "acoustic":
                        // Violão acústico: Karplus-Strong harmônico com decaimento natural e ruído de dedilhado
                        let fundamental = sin(2.0 * .pi * freq * t) * exp(-t * 2.2)
                        let harmonic2 = 0.45 * sin(2.0 * .pi * freq * 2.0 * t) * exp(-t * 3.5)
                        let harmonic3 = 0.2 * sin(2.0 * .pi * freq * 3.0 * t) * exp(-t * 5.0)
                        let harmonic4 = 0.08 * sin(2.0 * .pi * freq * 4.0 * t) * exp(-t * 7.0)
                        
                        // Ruído de palhetada (pluck impulse) no primeiro 0.05s
                        let pluckNoise = (Float.random(in: -1.0...1.0) * exp(-t * 100.0)) * 0.15
                        voiceSample = (fundamental + harmonic2 + harmonic3 + harmonic4) * 0.45 + pluckNoise
                        
                    case "bass":
                        // Baixo elétrico: 1 oitava abaixo (freq * 0.5), harmônicos cortados rapidamente para graves profundos
                        let bassFreq = freq * 0.5
                        let fundamental = sin(2.0 * .pi * bassFreq * t) * exp(-t * 2.5)
                        let harmonic2 = 0.35 * sin(2.0 * .pi * bassFreq * 2.0 * t) * exp(-t * 5.0)
                        let harmonic3 = 0.1 * sin(2.0 * .pi * bassFreq * 3.0 * t) * exp(-t * 8.0)
                        voiceSample = (fundamental + harmonic2 + harmonic3) * 0.7
                        
                    case "drums":
                        // Bateria física sintética baseada na corda que foi dedilhada
                        if string == 6 || string == 5 {
                            // Bumbo (Kick): seno com queda de frequência rápida e decay acentuado
                            let sweepFreq = max(42.0, 140.0 - t * 1200.0)
                            voiceSample = sin(2.0 * .pi * sweepFreq * t) * exp(-t * 18.0) * 0.8
                        } else if string == 4 || string == 3 {
                            // Caixa (Snare): Ruído branco com envelope curto e tom de ressonância da pele
                            let body = sin(2.0 * .pi * 175.0 * t) * exp(-t * 25.0)
                            let snareNoise = Float.random(in: -1.0...1.0) * exp(-t * 16.0)
                            voiceSample = (body * 0.35 + snareNoise * 0.65) * 0.6
                        } else {
                            // Prato / Hi-hat: Ruído branco puro e curto para simular o ataque do metal
                            let hihatNoise = Float.random(in: -1.0...1.0) * exp(-t * 55.0)
                            voiceSample = hihatNoise * 0.22
                        }
                        
                    case "keys":
                        // Teclado/Piano: Harmônicos ricos equilibrados com decay longo e suave
                        let fundamental = sin(2.0 * .pi * freq * t) * exp(-t * 1.2)
                        let harmonic2 = 0.5 * sin(2.0 * .pi * freq * 2.0 * t) * exp(-t * 1.8)
                        let harmonic3 = 0.35 * sin(2.0 * .pi * freq * 3.0 * t) * exp(-t * 2.5)
                        let harmonic4 = 0.2 * sin(2.0 * .pi * freq * 4.0 * t) * exp(-t * 3.5)
                        let harmonic5 = 0.1 * sin(2.0 * .pi * freq * 5.0 * t) * exp(-t * 5.0)
                        voiceSample = (fundamental + harmonic2 + harmonic3 + harmonic4 + harmonic5) * 0.4
                        
                    default:
                        // Guitarra Elétrica: Ondas ricas com saturação suave simulando overdrive/distorção
                        let fundamental = sin(2.0 * .pi * freq * t) * exp(-t * 1.5)
                        let harmonic2 = 0.62 * sin(2.0 * .pi * freq * 2.0 * t) * exp(-t * 2.2)
                        let harmonic3 = 0.42 * sin(2.0 * .pi * freq * 3.0 * t) * exp(-t * 3.0)
                        let harmonic4 = 0.25 * sin(2.0 * .pi * freq * 4.0 * t) * exp(-t * 4.5)
                        
                        let rawSound = (fundamental + harmonic2 + harmonic3 + harmonic4) * 0.5
                        // Curva de saturação não-linear (overdrive de válvula)
                        let saturated = atan(rawSound * 2.5) / 1.5
                        voiceSample = saturated
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
    
    private func startEngineIfNeeded() {
        guard !isEngineRunning else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            isEngineRunning = true
        } catch {
            print("Erro ao iniciar AVAudioEngine de síntese:", error)
        }
    }
    
    private func normalizeInstrument(_ instrument: String) -> String {
        let lower = instrument.lowercased()
        if lower.contains("violão") || lower.contains("acoustic") {
            return "acoustic"
        } else if lower.contains("baixo") || lower.contains("bass") {
            return "bass"
        } else if lower.contains("bateria") || lower.contains("drum") || lower.contains("drums") {
            return "drums"
        } else if lower.contains("teclado") || lower.contains("piano") || lower.contains("keys") || lower.contains("keyboard") {
            return "keys"
        } else {
            return "guitar"
        }
    }
    
    /// Toca uma nota por número MIDI (ex: 40 = E2, 60 = C4, 64 = E4) com timbre específico
    func playNote(midi: Int, instrument: String = "Guitarra", string: Int = 1) {
        startEngineIfNeeded()
        
        let freq = 440.0 * pow(2.0, Float(midi - 69) / 12.0)
        let normalized = normalizeInstrument(instrument)
        
        voiceLock.lock()
        // Limita a polifonia a 6 vozes simultâneas
        if activeVoices.count > 6 {
            activeVoices.removeFirst()
        }
        activeVoices.append(ActiveVoice(frequency: freq, time: 0.0, sampleRate: 44100.0, isPlucked: true, instrument: normalized, string: string))
        voiceLock.unlock()
    }
    
    /// Toca nota por corda (1 a 6), casa (fret) e timbre
    func playFret(string: Int, fret: Int, instrument: String = "Guitarra") {
        // Afinação Padrão: 6=E2(40), 5=A2(45), 4=D3(50), 3=G3(55), 2=B3(59), 1=E4(64)
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
        playNote(midi: midi, instrument: instrument, string: string)
    }
    
    /// Toca um clique de metrônomo curto
    func playMetronomeTick(isStrong: Bool) {
        startEngineIfNeeded()
        let freq: Float = isStrong ? 900.0 : 600.0
        voiceLock.lock()
        if activeVoices.count > 6 {
            activeVoices.removeFirst()
        }
        activeVoices.append(ActiveVoice(frequency: freq, time: 0.0, sampleRate: 44100.0, isPlucked: true, instrument: "metronome", string: 1))
        voiceLock.unlock()
    }
    
    /// Para todas as notas ativas
    func stopAll() {
        voiceLock.lock()
        activeVoices.removeAll()
        voiceLock.unlock()
    }
}
