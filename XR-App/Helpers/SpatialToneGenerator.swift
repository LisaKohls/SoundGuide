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

    private(set) var sourcePosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
    private var listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
    private var dynamicVolume: Float = 1.0

    init(frequency: Double = 1200.0, duration: TimeInterval = 0.1, interval: TimeInterval = 1.0) {
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

        player.renderingAlgorithm = .auto
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
            self.player.position = self.sourcePosition
            self.environment.listenerPosition = self.listenerPosition
            self.player.volume = self.dynamicVolume

            self.player.scheduleBuffer(buffer, at: nil, options: [])
        }
    }
    
    func updateDistanceFeedback(distance: Float) {
        let clampedDistance = min(max(distance, 0.0), 2.5)  // maxDistance = 2.5

        let newVolume = volumeForDistance(clampedDistance)
        let newInterval = intervalForDistance(clampedDistance)

        if abs(newVolume - dynamicVolume) > 0.01 {
            dynamicVolume = newVolume
            player.volume = newVolume
        }

        if abs(newInterval - interval) > 0.01 {
            interval = newInterval
            timer?.invalidate()
            startPingLoop()
        }

        print("📏 Distance: \(String(format: "%.3f", distance)) m | 🔊 Volume: \(String(format: "%.2f", dynamicVolume)) | ⏱ Interval: \(String(format: "%.2f", interval))s")
    }


    private func volumeForDistance(_ distance: Float) -> Float {
        let maxDistance: Float = 2.5
        let minVolume: Float = 0.1
        let maxVolume: Float = 1.0

        let clamped = min(max(distance, 0), maxDistance)
        let inverted = maxDistance - clamped
        let normalized = inverted / maxDistance  // 0 (weit weg) ... 1 (nah dran)

        // Exponentiell skalieren für größere Unterschiede bei naher Distanz
        let scaled = pow(normalized, 2.5)
        let volume = minVolume + (maxVolume - minVolume) * scaled

        return volume
    }

    private func intervalForDistance(_ distance: Float) -> TimeInterval {
        let nearDistance: Float = 0.5
        let maxDistance: Float = 2.0
        let clamped = max(min(distance, maxDistance), nearDistance)

        let normalized = (clamped - nearDistance) / (maxDistance - nearDistance) // 0.0 (nah) → 1.0 (fern)
        let exponent: Float = 6.0
        let minInterval: TimeInterval = 0.3
        let maxInterval: TimeInterval = 2.0

        let scaled = pow(normalized, exponent)
        return minInterval + Double(scaled) * (maxInterval - minInterval)
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
