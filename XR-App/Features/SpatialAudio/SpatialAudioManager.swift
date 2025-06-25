//
//  SpatialAudioManager.swift
//  XR-App
//
//  Created by Lisa Salzer on 25.06.25.
//
//  References:
//  [2] https://developer.apple.com/documentation/realitykit/spatialaudiocomponent
//  [3] https://developer.apple.com/documentation/realitykit/audiofileresource
//  [4] https://developer.apple.com/documentation/realitykit/entity
//

/*
 Abstract:
 Handles spatial audio playback and configuration (extracted from ViewModel)
 */

import Foundation
import RealityKit

final class SpatialAudioManager {
    static let shared = SpatialAudioManager()
    
    private var currentAudioController: AudioPlaybackController?
    
    private init() {}
    
    // Configure the spatial audio properties [2]
    func configureSpatialAudio(
        on entity: Entity,
        gain: Double = -2.0,
        focus: Double = 0.2,
        reverblevel: Double = 2.0,
        rolloffFactor: Double = 3.0
    ) {
        var spatialAudio = SpatialAudioComponent()
        spatialAudio.gain = Audio.Decibel(gain)
        spatialAudio.directivity = .beam(focus: focus)
        spatialAudio.reverbLevel = reverblevel
        spatialAudio.distanceAttenuation = .rolloff(factor: rolloffFactor)
        entity.components.set(spatialAudio)
    }
    
    // Recieve user-selected sound from user defaults
    func playSound(for entity: Entity) {
        let raw = UserDefaults.standard.string(forKey: "soundMode") ?? SoundMode.staticFile1.rawValue
        let soundMode = SoundMode(rawValue: raw) ?? .staticFile1
        playSpatialSound(for: entity, resourceName: soundMode.fileName, gain: soundMode.gain)
    }
    
    // Load and play spatial audio file with given parameters [3], [4]
    func playSpatialSound(for entity: Entity, resourceName: String, gain: Double) {
        do {
            // Retrieve and clamp audio settings from user defaults
            let reverb = UserDefaults.standard.double(forKey: "reverbLevel").clamped(to: 0.5...5.0)
            let rolloff = UserDefaults.standard.double(forKey: "rolloffFactor").clamped(to: 1.0...6.0)
            
            // Configure spatial audio based on current settings
            configureSpatialAudio(on: entity, gain: gain, focus: 1.0, reverblevel: reverb, rolloffFactor: rolloff)
            
            // Load the audio file from the main bundle
            let audioResource: AudioFileResource = try .load(named: resourceName, in: .main, configuration: .init(shouldLoop: true))
            
            // Prepare and play the audio
            let controller = entity.prepareAudio(audioResource)
            self.currentAudioController = controller
            self.currentAudioController?.play()
        } catch {
            print("Failed to load or play sound: \(error)")
        }
    }
    
    // Stop any currently playing spatial audio [3]
    func stopSound() {
        currentAudioController?.stop()
        currentAudioController = nil
    }
}
