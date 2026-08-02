import Foundation
import AVFoundation

/// Motor de síntese sonora nativo para reprodução de notas de violão e guitarra com precisão de estúdio
final class GuitarSynthEngine: ObservableObject {
    static let shared = GuitarSynthEngine()
    
    private var engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var isEngineRunning = false
    
    // Estado das cordas/vozes ativas
    private struct ActiveVoice {
        let frequency: Float
        var time: Float
        let sampleRate: Float
        var isPlucked: Bool
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
                    
                    // Síntese harmônica rica de corda de guitarra (Karplus-Strong simplificado com decaimento harmônico)
                    let fundamental = sin(2.0 * .pi * freq * t) * exp(-t * 2.8)
                    let harmonic2 = 0.5 * sin(2.0 * .pi * freq * 2.0 * t) * exp(-t * 3.8)
                    let harmonic3 = 0.25 * sin(2.0 * .pi * freq * 3.0 * t) * exp(-t * 5.0)
                    let harmonic4 = 0.12 * sin(2.0 * .pi * freq * 4.0 * t) * exp(-t * 6.5)
                    
                    sample += (fundamental + harmonic2 + harmonic3 + harmonic4) * 0.35
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
    
    /// Toca uma nota por número MIDI (ex: 40 = E2, 60 = C4, 64 = E4)
    func playNote(midi: Int) {
        startEngineIfNeeded()
        
        let freq = 440.0 * pow(2.0, Float(midi - 69) / 12.0)
        voiceLock.lock()
        // Limita a polifonia a 6 cordas simultâneas
        if activeVoices.count > 6 {
            activeVoices.removeFirst()
        }
        activeVoices.append(ActiveVoice(frequency: freq, time: 0.0, sampleRate: 44100.0, isPlucked: true))
        voiceLock.unlock()
    }
    
    /// Toca nota por corda (1 a 6) e casa (fret)
    func playFret(string: Int, fret: Int) {
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
        playNote(midi: midi)
    }
    
    /// Para todas as notas ativas
    func stopAll() {
        voiceLock.lock()
        activeVoices.removeAll()
        voiceLock.unlock()
    }
}
