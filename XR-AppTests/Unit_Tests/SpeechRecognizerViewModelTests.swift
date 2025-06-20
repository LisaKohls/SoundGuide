//
//  SpeechRecognizerViewModelTests.swift
//  XR-App
//
//  Created by Lisa Kohls on 17.05.25.
//

import XCTest
@testable import XR_App

final class SpeechRecognizerViewModelTests: XCTestCase {

    func test_onResultClosure_isCalledWithExpectedText() {
        let sut = SpeechRecognizerViewModel()

        let expectation = expectation(description: "onResult should be called")
        let expectedText = "hello world"
        var recognizedText: String?

        sut.onResult = { text in
            recognizedText = text
            expectation.fulfill()
        }

        sut.onResult?(expectedText)

        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(recognizedText, expectedText)
    }
}

