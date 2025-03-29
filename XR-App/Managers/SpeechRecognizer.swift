//
//  SpeechRecognizer.swift
//  XR-App
//
//  Created by Lisa Salzer on 29.03.25.
//

import Foundation
import Speech
import AVFoundation

class SpeechRecognizer: ObservableObject {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    var onResult: ((String) -> Void)?
    
    func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Fehler beim Konfigurieren der AudioSession: \(error)")
        }
    }
    
    func startRecognition() {
        SFSpeechRecognizer.requestAuthorization { status in
            print("try starting recognition")
            guard status == .authorized else { return }
            
            DispatchQueue.main.async {
                self.request = SFSpeechAudioBufferRecognitionRequest()
                let inputNode = self.audioEngine.inputNode
                let format = inputNode.outputFormat(forBus: 0)
                
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                    self.request?.append(buffer)
                }
                
                try? self.audioEngine.start()
                
                self.recognitionTask = self.recognizer?.recognitionTask(with: self.request!) { result, error in
                    if let result = result {
                        print("result in speechrecognizer: \(result.bestTranscription.formattedString)")
                        let spokenText = result.bestTranscription.formattedString.lowercased()
                        self.onResult?(spokenText)
                    }
                }
            }
        }
    }
    
    func stopRecognition() {
        audioEngine.stop()
        request?.endAudio()
        recognitionTask?.cancel()
    }
}

