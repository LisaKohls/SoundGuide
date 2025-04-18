//
//  SpatialToneGenerator.swift
//  XR-App
//
//  Created by Lisa Kohls on 05.04.25.
//

import AVFoundation

class SpatialToneGenerator {
    private let engine = AVAudioEngine()
    private let environment = AVAudioEnvironmentNode()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44100.0
    private var timer: Timer?

    private let frequency: Double
    private let duration: TimeInterval
    private var interval: TimeInterval
    private var audioFormat: AVAudioFormat!

    private var sourcePosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
    private var listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
    private var dynamicVolume: Float = 1.0

    init(
        frequency: Double = 1200.0,
        duration: TimeInterval = 0.1,
        interval: TimeInterval = 1.0
    ) {
        self.frequency = frequency
        self.duration = duration
        self.interval = interval

        self.audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        setup()
        startPingLoop()
    }

    private func setup() {
        engine.attach(environment)
        engine.attach(player)

        engine.connect(player, to: environment, format: audioFormat)
        engine.connect(environment, to: engine.mainMixerNode, format: nil)

        player.renderingAlgorithm = .auto // besser für Vision Pro / AirPods
        player.volume = 1.0

        environment.listenerPosition = listenerPosition

        try? engine.start()
        player.play()
    }

    private func createPingBuffer(frequency: Double, duration: TimeInterval) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let thetaIncrement = 2.0 * .pi * frequency / sampleRate
        var theta = 0.0

        for frame in 0..<Int(frameCount) {
            let sample = Float(sin(theta) * 0.4)
            buffer.floatChannelData![0][frame] = sample
            theta += thetaIncrement
        }

        return buffer
    }

    private func startPingLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }

            let buffer = self.createPingBuffer(frequency: self.frequency, duration: self.duration)

            // 📍 Spatial Position & Lautstärke setzen
            self.player.position = self.sourcePosition
            self.environment.listenerPosition = self.listenerPosition
            self.player.volume = self.dynamicVolume

            self.player.scheduleBuffer(buffer, at: nil, options: [])
        }
    }

    /// 🔁 Wird regelmäßig mit neuer Distanz (in Metern) aufgerufen
    func updateDistanceFeedback(distance: Float) {
        let dist = Double(distance)

        // 🔊 Lautstärke: Logarithmisch fallend mit Entfernung
        let volume = max(0.01, min(1.0, 1.5 - log2(dist + 1)))
        self.dynamicVolume = Float(volume)

        // ⏱ Intervall: Näher = häufiger
        let newInterval = max(0.1, min(1.5, dist * 0.5))

        if abs(newInterval - interval) > 0.01 {
            self.interval = newInterval
            timer?.invalidate()
            startPingLoop()
        }

        print("🎯 Distance: \(String(format: "%.2f", dist)) m | 🔊 Volume: \(volume) | ⏱ Interval: \(newInterval)s")
    }

    /// 📍 Quellposition des Sounds im 3D-Raum aktualisieren
    func updateSourcePosition(x: Float, y: Float, z: Float) {
        self.sourcePosition = AVAudio3DPoint(x: x, y: y, z: z)
        print("source Position: \(sourcePosition)")
    }

    /// 🎧 Listener-Position aktualisieren (z. B. Kamera/Nutzer)
    func updateListenerPosition(x: Float, y: Float, z: Float) {
        listenerPosition = AVAudio3DPoint(x: x, y: y, z: z)
        print("listenerPosition: \(listenerPosition)")
    }

    /// 🛑 AudioEngine stoppen
    func stop() {
        timer?.invalidate()
        player.stop()
        engine.stop()
    }
}
