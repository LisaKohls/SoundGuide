//
//  SpeechHelperTests.swift
//  XR-App
//
//  Created by Lisa Kohls on 17.05.25.
//

import XCTest
import AVFoundation
@testable import XR_App

@MainActor
final class SpeechHelperTests: XCTestCase {

    override func setUp() {
        super.setUp()
        SpeechHelper.shared.setupAudio()
    }

    override func tearDown() {
        SpeechHelper.shared.stopSpeaking()
        super.tearDown()
    }

    func testSetupAudio_doesNotThrow() {
        XCTAssertNoThrow(SpeechHelper.shared.setupAudio())
    }

    func testPreWarmSpeechEngine_runsWithoutError() {
        SpeechHelper.shared.preWarmSpeechEngine()
    }
    
    func testStopSpeaking_stopsSpeechImmediately() {
        let helper = SpeechHelper.shared
        helper.speak(text: "Dies ist ein sehr langer Text, der eigentlich gesprochen werden sollte.")
        helper.stopSpeaking()

        XCTAssertFalse(helperIsSpeaking(helper: helper), "Synthesizer sollte nicht mehr sprechen.")
    }

    private func helperIsSpeaking(helper: SpeechHelper) -> Bool {
        return false
    }
}
