//
//  SpeechHelper.swift
//  XR-App
//
//  Created by Lisa Kohls on 08.05.25.
//

/*
 Abstract:
 The speech helper for the speech output.
 */

import AVFoundation
import Foundation
import Speech

@MainActor
class SpeechHelper: NSObject, AVSpeechSynthesizerDelegate {
    
    static let shared = SpeechHelper()
    
    private let synthesizer = AVSpeechSynthesizer()
    private var onFinishSpeaking: (() -> Void)?
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        } catch {
            print("AudioSession Error: \(error)")
        }
    }
    
    func preWarmSpeechEngine() {
        let dummy = AVSpeechUtterance(string: "                       ")
        dummy.voice = AVSpeechSynthesisVoice(language: "LANG".localized)
        dummy.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(dummy)
    }
    
    func speak(text: String, language: String = "LANG".localized, rate: Float = UserDefaults.standard.float(forKey: "speechRate"), onFinish: (() -> Void)? = nil) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        
        self.onFinishSpeaking = onFinish
        synthesizer.speak(utterance)
        print(String(describing: utterance.speechString))
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinishSpeaking?()
        onFinishSpeaking = nil
    }
    
}
