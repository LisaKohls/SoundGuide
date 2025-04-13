//
//  SpeechRecognizerViewModel.swift
//  XR-App
//
//  Created by Lisa Kohls on 13.04.25.
//

import AVFoundation
import Foundation

class SpeechRecognizerViewModel: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(text: String, language: String = "de-DE", rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
        print("Sprachausgabe erhalten: \(text)")
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        synthesizer.speak(utterance)
    }
}
