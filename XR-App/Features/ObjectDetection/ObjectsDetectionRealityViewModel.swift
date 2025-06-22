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
    private var toneGenerators: [UUID: SpatialToneGenerator] = [:]
    
    //Set Default Sound
    //var soundMode: SoundMode = .staticFile(name: "spatial-sound.wav") // Soundfile
    var soundMode: SoundMode = .staticFile(name: "E10.wav") // Soundfile
    //var soundMode: SoundMode = .dynamic //Dynamic sound generation
    
    
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
    
    func playSound(for id: UUID, entity: Entity, at position: SIMD3<Float>) {
        switch soundMode {
        case .staticFile(let name):
            playAmbientSound(for: entity, resourceName: name)
        case .dynamic:
            startDynamicSound(for: id, at: position)
        }
    }
    
    func updateSound(for id: UUID, at position: SIMD3<Float>) {
        if case .dynamic = soundMode {
            updateDynamicSound(for: id, at: position)
        }
    }
    
    func stopSound(for id: UUID) {
        switch soundMode {
        case .staticFile:
            stopAmbientSound()
        case .dynamic:
            stopDynamicSound(for: id)
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
    
    
    func playAmbientSound(for entity: Entity, resourceName: String) {
        do {
            configureSpatialAudio(on: entity, gain: 0, focus: 1.0, reverblevel: 5, rolloffFactor: 3.0)
            let audiosource: AudioFileResource = try .load(named: resourceName, in: .main, configuration: .init(shouldLoop: true))
            let controller = entity.prepareAudio(audiosource)
            self.currentAudioController = controller
            self.currentAudioController?.play()
        } catch {
            print("Failed to load or play sound: \(error)")
        }
    }
    
    
    func stopAmbientSound() {
        currentAudioController?.stop()
        currentAudioController = nil
    }
    
    
    func startDynamicSound(for id: UUID, at position: SIMD3<Float>) {
        let generator = SpatialToneGenerator()
        generator.updateSourcePosition(x: position.x, y: position.y, z: position.z)
        generator.updateListenerPosition(x: 0, y: 0, z: 0)
        toneGenerators[id] = generator
    }
    
    
    func updateDynamicSound(for id: UUID, at position: SIMD3<Float>) {
        guard let generator = toneGenerators[id] else { return }
        generator.updateSourcePosition(x: position.x, y: position.y, z: position.z)
        generator.updateListenerPosition(x: 0, y: 0, z: 0)
        let distance = simd_length(position - SIMD3<Float>(0, 0, 0))
        generator.updateDistanceFeedback(distance: distance)
    }
    
    func stopDynamicSound(for id: UUID) {
        toneGenerators[id]?.stop()
        toneGenerators.removeValue(forKey: id)
    }
    
    func updateListenerPosition(x: Float, y: Float, z: Float) {
        for generator in toneGenerators.values {
            generator.updateListenerPosition(x: x, y: y, z: z)
            
            let source = SIMD3<Float>(generator.sourcePosition.x, generator.sourcePosition.y, generator.sourcePosition.z)
            let listener = SIMD3<Float>(x, y, z)
            let distance = simd_length(source - listener)
            generator.updateDistanceFeedback(distance: distance)
        }
    }
    
}
