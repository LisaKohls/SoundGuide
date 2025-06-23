//
//  ObjectsDetectionRealityViewModel.swift
//  XR-App
//
//  Created by Lisa Kohls on 07.05.25.
//

/*
 Abstract:
 ObjectsDetectionRealityViewModel which creates hand entities and enables an easy use for the ObjectsDetectionRealityView.
 */

import Foundation
import RealityKit
import SwiftUI
import Combine

@MainActor
class ObjectsDetectionRealityViewModel: ObservableObject {
    
    private var spokenObjectNames: Set<String> = []
    private var currentAudioController: AudioPlaybackController?

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
    
    private func configureSpatialAudio(
            on entity: Entity,
            gain: Double = -10.0,
            focus: Double = 0.2,
            reverblevel: Double = 1.0,
            rolloffFactor: Double = 2.0
        ){
            var spatialAudio = SpatialAudioComponent()
            spatialAudio.gain = Audio.Decibel(gain)
            spatialAudio.directivity = .beam(focus: focus)
            spatialAudio.reverbLevel = reverblevel
            spatialAudio.distanceAttenuation = .rolloff(factor: rolloffFactor)
            entity.components.set(spatialAudio)
        }
    
    
    func playSound(entity: Entity) {
        let raw = UserDefaults.standard.string(forKey: "soundMode") ?? SoundMode.staticFile1.rawValue
        let soundMode = SoundMode(rawValue: raw) ?? .staticFile1
        print("🔊 Loaded soundMode rawValue: \(raw), resolved file: \(soundMode.fileName)")
        playSpatialSound(for: entity, resourceName: soundMode.fileName, gain: soundMode.gain)
    }
    
    func playSpatialSound(for entity: Entity, resourceName: String, gain: Double) {
            do {
                let reverb = UserDefaults.standard.double(forKey: "reverbLevel").clamped(to: 0...10)
                let rolloff = UserDefaults.standard.double(forKey: "rolloffFactor").clamped(to: 0.1...10)
                
                configureSpatialAudio(on: entity, gain: gain, focus: 1.0, reverblevel: reverb, rolloffFactor: rolloff)
                
                let audioResource: AudioFileResource = try .load(named: resourceName, in: .main, configuration: .init(shouldLoop: true))
                let controller = entity.prepareAudio(audioResource)
                self.currentAudioController = controller
                self.currentAudioController?.play()
            } catch {
                print("Failed to load or play sound: \(error)")
            }
    }

    func stopSpatialSound() {
        currentAudioController?.stop()
        currentAudioController = nil
    }
    
}
