//
//  HomeContentUITest.swift
//  XR-App
//
//  Created by Lisa Kohls on 17.05.25.
//

import XCTest

final class HomeContentUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func test_speechRecognizerFlow() {
        let startRecordingBtn = app.buttons["STARTRECORDING_BTN".localized]
        let speechText = app.staticTexts["NORECORDEDOBJECT".localized]

        XCTAssertTrue(startRecordingBtn.waitForExistence(timeout: 5), "Repeat button should exist on Home View")

        startRecordingBtn.tap()

        XCTAssertTrue(speechText.waitForExistence(timeout: 5), "SpeechRecognizerView should show 'No object recorded' text")
        
        XCTAssertTrue(startRecordingBtn.waitForExistence(timeout: 10), "Should lead to recording screen")
    }
}

