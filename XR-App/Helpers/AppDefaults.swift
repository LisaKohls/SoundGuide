//
//  AppDefaults.swift
//  XR-App
//
//  Created by Lisa Salzer on 23.06.25.
//
//  Reference: https://developer.apple.com/documentation/foundation/userdefaults/
//

/*
 Abstract:
 Registering default values in UserDefaults.
 */

import Foundation

enum AppDefaults {
    static func register() {
        UserDefaults.standard.register(defaults: [
            "speechRate": 0.55,
            "soundMode": SoundMode.staticFile1.rawValue,
            "reverbLevel": 2.0,
            "rolloffFactor": 3.0
        ])
    }
}
