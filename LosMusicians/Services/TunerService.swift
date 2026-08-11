import Foundation
import AVFoundation

class TunerService: ObservableObject {
    @Published var currentPitch: Float = 0.0
    @Published var closestNote: String = "-"
    @Published var centsDistance: Float = 0.0
    @Published var isRunning: Bool = false
    
    private let audioEngine = AVAudioEngine()
    
    // Todas as notas com suas frequências base (A4 = 440Hz)
    private let noteFrequencies: [(name: String, freq: Float)] = [
        ("C2", 65.41), ("C#2", 69.30), ("D2", 73.42), ("D#2", 77.78),
        ("E2", 82.41), ("F2", 87.31), ("F#2", 92.50), ("G2", 98.00),
        ("G#2", 103.83), ("A2", 110.00), ("A#2", 116.54), ("B2", 123.47),
        
        ("C3", 130.81), ("C#3", 138.59), ("D3", 146.83), ("D#3", 155.56),
        ("E3", 164.81), ("F3", 174.61), ("F#3", 185.00), ("G3", 196.00),
        ("G#3", 207.65), ("A3", 220.00), ("A#3", 233.08), ("B3", 246.94),
        
        ("C4", 261.63), ("C#4", 277.18), ("D4", 293.66), ("D#4", 311.13),
        ("E4", 329.63), ("F4", 349.23), ("F#4", 369.99), ("G4", 392.00),
        ("G#4", 415.30), ("A4", 440.00), ("A#4", 466.16), ("B4", 493.88),
        
        ("C5", 523.25), ("C#5", 554.37), ("D5", 587.33), ("D#5", 622.25),
        ("E5", 659.25), ("F5", 698.46), ("F#5", 739.99), ("G5", 783.99),
        ("G#5", 830.61), ("A5", 880.00), ("A#5", 932.33), ("B5", 987.77)
    ]
    
    func start() {
        guard !isRunning else { return }
        
        // Solicita permissão de áudio
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            guard granted else {
                print("Permissão de gravação de áudio negada.")
                return
            }
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers, .allowBluetoothA2DP])
                try AVAudioSession.sharedInstance().setActive(true)
                
                let inputNode = self.audioEngine.inputNode
                let format = inputNode.outputFormat(forBus: 0)
                
                inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, time in
                    self.processAudioBuffer(buffer: buffer)
                }
                
                try self.audioEngine.start()
                DispatchQueue.main.async {
                    self.isRunning = true
                }
            } catch {
                print("Erro ao iniciar AVAudioEngine para o afinador: \(error)")
            }
        }
    }
    
    func stop() {
        guard isRunning else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRunning = false
    }
    
    private func processAudioBuffer(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        let sampleRate = Float(buffer.format.sampleRate)
        
        // Zero-Crossing Detection simplificado
        var zeroCrossings = 0
        var prevValue = channelData[0]
        
        for i in 1..<frameLength {
            let currentValue = channelData[i]
            if (prevValue < 0 && currentValue >= 0) || (prevValue >= 0 && currentValue < 0) {
                zeroCrossings += 1
            }
            prevValue = currentValue
        }
        
        let frequency = (Float(zeroCrossings) * sampleRate) / Float(2 * frameLength)
        
        // Filtra ruídos
        if frequency > 40 && frequency < 1000 {
            updatePitch(frequency: frequency)
        }
    }
    
    private func updatePitch(frequency: Float) {
        // Encontra a nota mais próxima
        var closest = noteFrequencies[0]
        var minDistance = abs(frequency - closest.freq)
        
        for note in noteFrequencies {
            let distance = abs(frequency - note.freq)
            if distance < minDistance {
                minDistance = distance
                closest = note
            }
        }
        
        // Calcula Cents (100 cents = 1 semitom)
        // Cents = 1200 * log2(freq / base_freq)
        let cents = 1200.0 * log2f(frequency / closest.freq)
        
        DispatchQueue.main.async {
            // Suaviza a leitura para não pular tanto
            self.currentPitch = self.currentPitch * 0.8 + frequency * 0.2
            self.closestNote = closest.name
            
            let smoothCents = self.centsDistance * 0.7 + cents * 0.3
            // Trava em +- 50 cents
            self.centsDistance = max(-50.0, min(50.0, smoothCents))
        }
    }
}
