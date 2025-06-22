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
    
    //Set Default Sound
    //var soundMode: SoundMode = .staticFile1(name: "E10.wav") // Soundfile
    //var soundMode: SoundMode = .staticFile2(name: "spatial-sound.wav") // Soundfile
    var soundMode: SoundMode = .staticFile3(name: "E1.wav") // Soundfile
    //var soundMode: SoundMode = .staticFile4(name: "S8.wav") // Soundfile
    //var soundMode: SoundMode = .staticFile5(name: "S6.wav") // Soundfile
    
    
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
            switch soundMode {
            case .staticFile1(let name):
                playSpatialSound(for: entity, resourceName: name)
            case .staticFile2(let name):
                playSpatialSound(for: entity, resourceName: name)
            case .staticFile3(name: let name):
                playSpatialSound(for: entity, resourceName: name)
            case .staticFile4(name: let name):
                playSpatialSound(for: entity, resourceName: name)
            }
        }
    
    func playSpatialSound(for entity: Entity, resourceName: String) {
            do {
                configureSpatialAudio(on: entity, gain: 0, focus: 1.0, reverblevel: 5, rolloffFactor: 4.0)
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
