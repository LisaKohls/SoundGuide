//
//  ReferenceObjectLoaderTests.swift
//  XR-App
//
//  Created by Lisa Kohls on 17.05.25.
//

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

    func test_initialState_isEmpty() {
        XCTAssertEqual(sut.referenceObjects.count, 0)
        XCTAssertEqual(sut.enabledReferenceObjects.count, 0)
        XCTAssertEqual(sut.progress, 1.0)
    }

    func test_addReferenceObject_increasesCount() async throws {
        let mockURL = try createMockReferenceObjectFile()

        await sut.addReferenceObject(mockURL)

        XCTAssertEqual(sut.referenceObjects.count, 1)
        XCTAssertEqual(sut.enabledReferenceObjects.count, 1)
        XCTAssertTrue(sut.didFinishLoading)
        XCTAssertEqual(sut.progress, 1.0)
    }

    func test_removeObject_decreasesCount() async throws {
        let mockURL = try createMockReferenceObjectFile()

        await sut.addReferenceObject(mockURL)
        XCTAssertEqual(sut.referenceObjects.count, 1)

        let added = sut.referenceObjects.first!
        sut.removeObject(added)

        XCTAssertEqual(sut.referenceObjects.count, 0)
        XCTAssertEqual(sut.enabledReferenceObjects.count, 0)
    }

    // MARK: - Helpers

    private func createMockReferenceObjectFile() throws -> URL {
        // 👇 Erstellt einen leeren Dummy .referenceobject file im temp-Verzeichnis
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".referenceobject")
        let data = try JSONEncoder().encode(MockReferenceObjectModel())
        try data.write(to: tempURL)
        return tempURL
    }
}

// MARK: - Mock: ReferenceObject

private struct MockReferenceObjectModel: Codable {
    let id: UUID = UUID()
}
