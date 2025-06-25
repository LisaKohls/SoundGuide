//
//  Finger.swift
//  XR-App
//
//  Created by Lisa Kohls on 01.05.25.
//  Reference: https://developer.apple.com/documentation/visionos/tracking-and-visualizing-hand-movement

/*
 Abstract:
 An enumeration representing each part of the finger that forms the hand's skeleton.
 */

enum Finger: Int, CaseIterable {
    case forearm
    case thumb
    case index
    case middle
    case ring
    case little
}
