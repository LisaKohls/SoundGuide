//
//  Bone.swift
//  XR-App
//
//  Created by Lisa Kohls on 01.05.25.
//  Reference: https://developer.apple.com/documentation/visionos/tracking-and-visualizing-hand-movement

/*
Abstract:
An enumeration that represents each part of the bone and defines the joint name from the hand skeleton.
*/

enum Bone: Int, CaseIterable {
    case arm
    case wrist
    case metacarpal
    case knuckle
    case intermediateBase
    case intermediateTip
    case tip
}
