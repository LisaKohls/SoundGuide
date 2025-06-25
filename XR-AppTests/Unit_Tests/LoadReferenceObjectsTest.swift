//
//  LoadReferenceObjectsTest.swift
//  XR-App
//
//  Created by Lisa Salzer on 20.06.25.
//
//  Reference: https://developer.apple.com/documentation/xctest/xctestcase
//

/*
 Abstract:
 Tests loading multiple `.referenceobject` files from the app bundle into ReferenceObjectLoader.
 Verifies successful loading and correct state updates.
 
 Note: Reference object files must be included under "Copy Bundle Resources" in the XR-AppTests target.
 */

@testable import XR_App
import XCTest
import RealityKit

@MainActor
final class ReferenceObjectLoaderTests: XCTestCase {
    private var sut: ReferenceObjectLoader!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = ReferenceObjectLoader()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    func test_loadMultipleReferenceObjectsFromBundle() async throws {
        let fileNames = ["erdbeertee", "JBL_Box", "Spices", "tasse", "Vanille_Tee", "zitronentee", "Meine Tasse"]
        for name in fileNames {
            guard let url = Bundle(for: type(of: self)).url(
                forResource: name,
                withExtension: "referenceobject",
            ) else {
                XCTFail("Datei nicht gefunden: \(name).referenceobject")
                continue
            }
            
            let loader = ReferenceObjectLoader()
            await loader.addReferenceObject(url)
            
            XCTAssertEqual(loader.referenceObjects.count, 1, "\(name) konnte nicht geladen werden")
            XCTAssertTrue(loader.didFinishLoading)
        }
    }
    
}
