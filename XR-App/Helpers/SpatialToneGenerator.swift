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
    private let reverb = AVAudioUnitReverb()
    private let pitchControl = AVAudioUnitTimePitch()
    
    private let sampleRate = 44100.0
    private var timer: Timer?

    private let baseFrequency: Double
    private let duration: TimeInterval
    private var interval: TimeInterval
    private var audioFormat: AVAudioFormat!

    private(set) var sourcePosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
    private var listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
    private var dynamicVolume: Float = 1.0

    init(frequency: Double = 1200.0, duration: TimeInterval = 0.1, interval: TimeInterval = 1.0) {
        self.baseFrequency = frequency
        self.duration = duration
        self.interval = interval
        self.audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        setup()
        startPingLoop()
    }

    private func setup() {
        engine.attach(environment)
        engine.attach(player)
        engine.attach(reverb)
        engine.attach(pitchControl)

        reverb.loadFactoryPreset(.mediumRoom)
        reverb.wetDryMix = 40

        // Audio-Routing: Player → Pitch → Reverb → Environment
        engine.connect(player, to: pitchControl, format: audioFormat)
        engine.connect(pitchControl, to: reverb, format: audioFormat)
        engine.connect(reverb, to: environment, format: audioFormat)
        engine.connect(environment, to: engine.mainMixerNode, format: nil)

        player.renderingAlgorithm = .HRTF
        player.volume = dynamicVolume

        environment.listenerPosition = listenerPosition
        environment.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: 0, pitch: 0, roll: 0)

        try? engine.start()
        player.play()
    }

    private func createPingBuffer(frequency: Double, duration: TimeInterval) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let base = sin(2.0 * .pi * frequency * t)
            let overtone1 = 0.3 * sin(2.0 * .pi * frequency * 2 * t)
            let overtone2 = 0.2 * sin(2.0 * .pi * frequency * 3 * t)
            let envelope = exp(-8.0 * t)
            let sample = Float((base + overtone1 + overtone2) * envelope * 0.5)
            buffer.floatChannelData![0][frame] = sample
        }

        return buffer
    }

    private func startPingLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }

            let buffer = self.createPingBuffer(frequency: self.baseFrequency, duration: self.duration)

            // Spatial Position
            self.player.position = self.sourcePosition
            self.environment.listenerPosition = self.listenerPosition

            // Lautstärke
            self.player.volume = self.dynamicVolume

            // Stereo-Panning über Position (nur subtil)
            let pan = min(max(self.sourcePosition.x / 2.0, -1.0), 1.0)
            self.player.pan = pan

            self.player.scheduleBuffer(buffer, at: nil, options: [])
        }
    }

    func updateDistanceFeedback(distance: Float) {
        let clampedDistance = min(max(distance, 0.0), 2.5)

        // Lautstärke
        let newVolume = volumeForDistance(clampedDistance)

        // Intervall
        let newInterval = intervalForDistance(clampedDistance)

        // Pitch-Shifting abhängig von Entfernung (je näher, desto höher)
        let pitchValue = pitchForDistance(clampedDistance)
        pitchControl.pitch = pitchValue

        if abs(newVolume - dynamicVolume) > 0.01 {
            dynamicVolume = newVolume
            player.volume = newVolume
        }

        if abs(newInterval - interval) > 0.01 {
            interval = newInterval
            timer?.invalidate()
            startPingLoop()
        }

        print("📏 Distance: \(String(format: "%.2f", distance)) m | 🔊 Volume: \(String(format: "%.2f", dynamicVolume)) | ⏱ Interval: \(String(format: "%.2f", interval))s | 🎵 Pitch: \(Int(pitchValue))")
    }

    private func volumeForDistance(_ distance: Float) -> Float {
        let maxDistance: Float = 2.5
        let minVolume: Float = 0.1
        let maxVolume: Float = 1.0

        let clamped = min(max(distance, 0), maxDistance)
        let inverted = maxDistance - clamped
        let normalized = inverted / maxDistance
        let scaled = pow(normalized, 2.5)
        return minVolume + (maxVolume - minVolume) * scaled
    }

    private func intervalForDistance(_ distance: Float) -> TimeInterval {
        let nearDistance: Float = 0.5
        let maxDistance: Float = 2.0
        let clamped = max(min(distance, maxDistance), nearDistance)

        let normalized = (clamped - nearDistance) / (maxDistance - nearDistance)
        let exponent: Float = 6.0
        let minInterval: TimeInterval = 0.3
        let maxInterval: TimeInterval = 2.0

        let scaled = pow(normalized, exponent)
        return minInterval + Double(scaled) * (maxInterval - minInterval)
    }

    private func pitchForDistance(_ distance: Float) -> Float {
        let maxDistance: Float = 2.5
        let clamped = min(max(distance, 0), maxDistance)
        let normalized = 1.0 - (clamped / maxDistance)
        return normalized * 800 // in Cents (100 = 1 Halbton)
    }

    func updateSourcePosition(x: Float, y: Float, z: Float) {
        self.sourcePosition = AVAudio3DPoint(x: x, y: y, z: z)
    }

    func updateListenerPosition(x: Float, y: Float, z: Float) {
        listenerPosition = AVAudio3DPoint(x: x, y: y, z: z)
    }

    func stop() {
        timer?.invalidate()
        player.stop()
        engine.stop()
    }
}

