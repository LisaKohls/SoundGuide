//
//  ObjectsDetectionRealityViewModel.swift
//  XR-App
//
//  Created by Lisa Kohls on 07.05.25.
//

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
    
    func playSpatialSound(for entity: Entity, named resourceName: String = "spatial-sound.wav") {
            do {
                let resource: AudioFileResource = try .load(named: resourceName, in: .main)
                let controller = entity.prepareAudio(resource)
                controller.play()
                self.currentAudioController = controller
            } catch {
                print("Failed to load or play sound: \(error)")
            }
        }

    func stopSpatialSound() {
        currentAudioController?.stop()
        currentAudioController = nil
    }
}
