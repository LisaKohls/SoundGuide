//
//  ObjectsDetectionRealityViewModel.swift
//  XR-App
//
//  Created by Lisa Kohls on 07.05.25.
//
//  References:
//  [1] https://developer.apple.com/documentation/visionos/tracking-and-visualizing-hand-movement
//  [2] https://developer.apple.com/documentation/realitykit/spatialaudiocomponent
//  [3] https://developer.apple.com/documentation/realitykit/audiofileresource
//  [4] https://developer.apple.com/documentation/realitykit/entity
//

/*
 Abstract:
 A view model for managing the ObjectsDetectionRealityView.
 Handles the creation of hand-tracking entities, detection and labeling of objects,
 and playback of spatial audio for identified objects using user-defined audio settings.
 */

import Foundation
import RealityKit
import SwiftUI
import Combine

@MainActor
class ObjectsDetectionRealityViewModel: ObservableObject {
    
    private var spokenObjectNames: Set<String> = []
    private var currentAudioController: AudioPlaybackController?
    
    // [1]
    func makeHandEntities(in content: any RealityViewContentProtocol) {
        // Add the left hand.
        let leftHand = Entity()
        leftHand.name = "leftHand"
        leftHand.components.set(HandTrackingComponent(chirality: .left))
        leftHand.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.03)]))
        leftHand.components.set(PhysicsBodyComponent(mode: .kinematic))
        content.add(leftHand)
        
        // Add the right hand.
        let rightHand = Entity()
        rightHand.name = "rightHand"
        rightHand.components.set(HandTrackingComponent(chirality: .right))
        rightHand.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.03)]))
        rightHand.components.set(PhysicsBodyComponent(mode: .kinematic))
        content.add(rightHand)
    }
    
    func getDetectedObjectName(detectedObject: String) -> String {
        return switch detectedObject {
        case "tasse": "MUG".localized
        case "spices": "SPICES".localized
        case "erdbeertee": "STRAWBERRYTEA".localized
        case "zitronentee": "LEMONTEA".localized
        case "vanille tee": "VANILLATEA".localized
        default: detectedObject.lowercased()
        }
    }
    
    func observeTouchedObject(for entity: Entity, onTouch: @escaping (String) -> Void) {
        HandTrackingSystem.detectedObjects.append(entity)
        
        HandTrackingSystem.onObjectTouched = { [weak self] name in
            guard let self, !self.spokenObjectNames.contains(name) else { return }
            self.spokenObjectNames.insert(name)
            onTouch(name)
        }
    }
    
    // Configure the spatial audio properties [2] (implemented by Lisa Salzer)
    private func configureSpatialAudio(
        on entity: Entity,
        gain: Double = -2.0,
        focus: Double = 0.2,
        reverblevel: Double = 2.0,
        rolloffFactor: Double = 3.0
    ){
        var spatialAudio = SpatialAudioComponent()
        spatialAudio.gain = Audio.Decibel(gain)
        spatialAudio.directivity = .beam(focus: focus)
        spatialAudio.reverbLevel = reverblevel
        spatialAudio.distanceAttenuation = .rolloff(factor: rolloffFactor)
        entity.components.set(spatialAudio)
    }
    
    // Recieve user-selected sound from user defaults (implemented by Lisa Salzer)
    func playSound(entity: Entity) {
        let raw = UserDefaults.standard.string(forKey: "soundMode") ?? SoundMode.staticFile1.rawValue
        let soundMode = SoundMode(rawValue: raw) ?? .staticFile1
        playSpatialSound(for: entity, resourceName: soundMode.fileName, gain: soundMode.gain)
    }
    
    // Load and play spatial audio file with given parameters [3], [4] (implemented by Lisa Salzer)
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
    
    // Stop any currently playing spatial audio [3] (implemented by Lisa Salzer)
    func stopSpatialSound() {
        currentAudioController?.stop()
        currentAudioController = nil
    }
    
}
