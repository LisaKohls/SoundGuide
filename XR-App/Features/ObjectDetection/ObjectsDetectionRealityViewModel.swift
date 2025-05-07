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
}
