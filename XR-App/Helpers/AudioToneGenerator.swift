import AVFoundation

class AudioToneGenerator {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let toneUnit = AVAudioUnitTimePitch()
    private var buffer: AVAudioPCMBuffer?
    
    init(frequency: Double = 440.0) {
        setupAudio(frequency: frequency)
    }

    private func setupAudio(frequency: Double) {
        let sampleRate = 44100.0
        let duration = 1.0 // 1 Sekunde
        let frameCount = Int(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        let thetaIncrement = 2.0 * .pi * frequency / sampleRate
        var theta = 0.0
        let amp = 0.2

        for frame in 0..<frameCount {
            let value = Float(sin(theta)) * Float(amp)
            buffer.floatChannelData!.pointee[frame] = value
            theta += thetaIncrement
        }

        self.buffer = buffer
        engine.attach(player)
        engine.attach(toneUnit)
        engine.connect(player, to: toneUnit, format: format)
        engine.connect(toneUnit, to: engine.mainMixerNode, format: format)

        try? engine.start()
    }

    func play() {
        guard let buffer else { return }
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.play()
    }

    func stop() {
        player.stop()
    }

    func updatePitch(forY y: Float) {
        let pitch = (y - 0.5) * 1200 // z. B. ±1 Oktave je nach Y-Wert
        toneUnit.pitch = pitch
    }
}
