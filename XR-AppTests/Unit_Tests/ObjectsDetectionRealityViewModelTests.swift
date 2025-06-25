//
//  ObjectsDetectionRealityViewModelTests.swift
//  XR-App
//
//  Created by Lisa Kohls on 17.05.25.
//

/*
 Abstract:
 Tests for object name detection, touch handling, and spatial audio playback in ObjectsDetectionRealityViewModel.
 */

@testable import XR_App
import XCTest
import RealityKit

@MainActor
final class ObjectsDetectionRealityViewModelTests: XCTestCase {
    
    private var sut: ObjectsDetectionRealityViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = ObjectsDetectionRealityViewModel()
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    func test_getDetectedObjectName_knownObject_returnsLocalizedName() {
        let name = sut.getDetectedObjectName(detectedObject: "tasse")
        XCTAssertEqual(name, "MUG".localized)
    }
    
    func test_getDetectedObjectName_unknownObject_returnsLowercased() {
        let name = sut.getDetectedObjectName(detectedObject: "unbekannt")
        XCTAssertEqual(name, "unbekannt")
    }
    
    func test_observeTouchedObject_triggersCallbackOnce() {
        let entity = Entity()
        entity.name = "testObject"
        
        let expectation = XCTestExpectation(description: "Callback called once")
        
        sut.observeTouchedObject(for: entity) { name in
            XCTAssertEqual(name, "testObject")
            expectation.fulfill()
        }
        
        HandTrackingSystem.onObjectTouched?("testObject")
        HandTrackingSystem.onObjectTouched?("testObject")
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_playAndStopSound_doesNotCrashAndPreparesAudio() {
        
        let entity = Entity()
        UserDefaults.standard.set(SoundMode.staticFile1.rawValue, forKey: "soundMode")
        UserDefaults.standard.set(2.0, forKey: "reverbLevel")
        UserDefaults.standard.set(3.0, forKey: "rolloffFactor")
        
        sut.playSound(entity: entity)
        sut.stopSpatialSound()
        
        XCTAssertNotNil(entity.components[SpatialAudioComponent.self])
    }
}
