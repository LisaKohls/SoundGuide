//
//  HandTrackingComponent.swift
//  XR-App
//
//  Created by Lisa Kohls on 07.05.25.
//
//  Reference: https://developer.apple.com/documentation/visionos/tracking-and-visualizing-hand-movement

/*
 Abstract:
 A component that tracks an entity to a hand.
 */

import RealityKit
import ARKit.hand_skeleton

/// A component that tracks the hand skeleton.
struct HandTrackingComponent: Component {
    /// The chirality for the hand this component tracks.
    let chirality: AnchoringComponent.Target.Chirality
    
    /// A lookup that maps each joint name to the entity that represents it.
    var fingers: [HandSkeleton.JointName: Entity] = [:]
    
    /// Creates a new hand-tracking component.
    /// - Parameter chirality: The chirality of the hand target.
    init(chirality: AnchoringComponent.Target.Chirality) {
        self.chirality = chirality
        HandTrackingSystem.registerSystem()
    }
}

