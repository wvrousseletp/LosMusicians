import Foundation
import AVFoundation
import Accelerate

class PitchDetector: ObservableObject {
    private var engine = AVAudioEngine()
    private var isRunning = false
    
    @Published var currentNote: String = "--"
    @Published var currentFrequency: Float = 0.0
    @Published var currentMidiNote: Int = 0
    
    func start() {
        guard !isRunning else { return }
        
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard granted else {
                print("Microphone permission denied")
                return
            }
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to setup audio session: \(error)")
            }
            
            DispatchQueue.main.async {
                self?.setupEngine()
            }
        }
    }
    
    private func setupEngine() {
        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        
        // Use a smaller buffer for lower latency, typically 1024 or 2048
        let bufferSize: AVAudioFrameCount = 2048
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, time in
            self?.processBuffer(buffer: buffer)
        }
        
        engine.prepare()
        do {
            try engine.start()
            isRunning = true
        } catch {
            print("Could not start audio engine: \(error)")
        }
    }
    
    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        currentNote = "--"
        currentFrequency = 0.0
    }
    
    private func processBuffer(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        let sampleRate = Float(buffer.format.sampleRate)
        
        // 1. Calculate RMS to act as a noise gate
        var rms: Float = 0.0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))
        
        // If the sound is too quiet, ignore
        if rms < 0.01 {
            DispatchQueue.main.async {
                self.currentNote = "--"
                self.currentFrequency = 0.0
            }
            return
        }
        
        // 2. Perform FFT
        let log2n = vDSP_Length(log2(Float(frameLength)))
        let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
        
        var realp = [Float](repeating: 0.0, count: frameLength / 2)
        var imagp = [Float](repeating: 0.0, count: frameLength / 2)
        
        var splitComplex = DSPSplitComplex(realp: &realp, imagp: &imagp)
        
        // Apply window function (Hanning)
        var window = [Float](repeating: 0.0, count: frameLength)
        vDSP_hann_window(&window, vDSP_Length(frameLength), Int32(vDSP_HANN_NORM))
        
        var windowedData = [Float](repeating: 0.0, count: frameLength)
        vDSP_vmul(channelData, 1, window, 1, &windowedData, 1, vDSP_Length(frameLength))
        
        windowedData.withUnsafeBufferPointer { pointer in
            pointer.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: frameLength / 2) { complexPointer in
                vDSP_ctoz(complexPointer, 2, &splitComplex, 1, vDSP_Length(frameLength / 2))
            }
        }
        
        vDSP_fft_zrip(fftSetup!, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
        
        // 3. Find magnitude and peak
        var magnitudes = [Float](repeating: 0.0, count: frameLength / 2)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(frameLength / 2))
        
        var maxMag: Float = 0.0
        var maxIndex: vDSP_Length = 0
        vDSP_maxvi(&magnitudes, 1, &maxMag, &maxIndex, vDSP_Length(frameLength / 2))
        
        vDSP_destroy_fftsetup(fftSetup)
        
        // 4. Convert bin index to frequency
        // The bin frequency is (index * sampleRate) / frameLength
        let frequency = Float(maxIndex) * sampleRate / Float(frameLength)
        
        DispatchQueue.main.async {
            // Filter out noise or unrealistically low/high guitar notes (E2 is ~82Hz, high notes ~1000Hz)
            if frequency > 60 && frequency < 1500 {
                self.currentFrequency = frequency
                let (noteName, midiNumber) = self.noteFromFrequency(frequency)
                self.currentNote = noteName
                self.currentMidiNote = midiNumber
            }
        }
    }
    
    private func noteFromFrequency(_ frequency: Float) -> (String, Int) {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let A4: Float = 440.0
        
        // n = 12 * log2(fn / 440) + 69
        let noteNumber = 12 * log2(frequency / A4) + 69
        let roundedNoteNumber = Int(round(noteNumber))
        
        if roundedNoteNumber >= 0 {
            let noteIndex = roundedNoteNumber % 12
            let octave = (roundedNoteNumber / 12) - 1
            return ("\(noteNames[noteIndex])\(octave)", roundedNoteNumber)
        }
        return ("--", 0)
    }
}
