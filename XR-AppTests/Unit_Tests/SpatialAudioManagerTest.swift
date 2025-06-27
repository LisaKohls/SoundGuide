//
//  SpatialAudioManager.swift
//  XR-AppTests
//
//  Created by Lisa Salzer on 25.06.25.
//

/* Tests the SpatialAudioManager, verifying correct spatial
 audio configuration and clamping of UserDefault values */

@testable import XR_App
import XCTest
import RealityKit

final class SpatialAudioManagerTests: XCTestCase {
    
    // Tests whether the method `configureSpatialAudio` applies the correct parameter values to the entity
    func testConfigureSpatialAudio_setsCorrectValues() {
        let entity = Entity()
        
        SpatialAudioManager.shared.configureSpatialAudio(
            on: entity,
            gain: -3.0,
            focus: 0.4,
            reverblevel: 1.5,
            rolloffFactor: 4.0
        )
        
        guard let component = entity.components[SpatialAudioComponent.self] else {
            XCTFail("SpatialAudioComponent was not set on entity.")
            return
        }
        
        XCTAssertEqual(component.gain, -3.0, accuracy: 0.001)
        XCTAssertEqual(component.reverbLevel, 1.5, accuracy: 0.001)
        
        if case let .rolloff(factor) = component.distanceAttenuation {
            XCTAssertEqual(factor, 4.0, accuracy: 0.001)
        } else {
            XCTFail("Expected .rolloff distance attenuation")
        }
    }
    
    // Tests whether the method `playSpatialSound` correctly reads values from UserDefaults and clamps them to the allowed value range before applying them
    func testPlaySpatialSound_clampsUserDefaultsValues() {
        let entity = Entity()
        UserDefaults.standard.set(10.0, forKey: "reverbLevel")
        UserDefaults.standard.set(-1.0, forKey: "rolloffFactor")
        
        SpatialAudioManager.shared.playSpatialSound(for: entity, resourceName: "example", gain: -2.0)
        
        guard let component = entity.components[SpatialAudioComponent.self] else {
            XCTFail("SpatialAudioComponent was not set.")
            return
        }
        
        XCTAssertEqual(component.reverbLevel, 5.0, accuracy: 0.001) // max-Wert
        if case let .rolloff(factor) = component.distanceAttenuation {
            XCTAssertEqual(factor, 1.0, accuracy: 0.001) // min-Wert
        } else {
            XCTFail("Expected .rolloff distance attenuation")
        }
    }
}
