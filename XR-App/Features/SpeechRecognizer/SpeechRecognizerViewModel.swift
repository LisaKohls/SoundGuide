//
//  SpeechRecognizerViewModel.swift
//  XR-App
//
//  Created by Lisa Kohls on 13.04.25.
//

import AVFoundation
import Foundation
import Speech

class SpeechRecognizerViewModel: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    var onResult: ((String) -> Void)?

    func speak(text: String, language: String = "de-DE", rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
        print("Sprachausgabe erhalten: \(text)")
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        synthesizer.speak(utterance)
    }

    func startRecognition() {
        stopRecognition()
        
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else { return }
            
            DispatchQueue.main.async {
                self.request = SFSpeechAudioBufferRecognitionRequest()
                let inputNode = self.audioEngine.inputNode
                let format = inputNode.outputFormat(forBus: 0)
                
                inputNode.removeTap(onBus: 0)
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                    self.request?.append(buffer)
                }
                
                self.recognitionTask = self.recognizer?.recognitionTask(with: self.request!) { result, error in
                    if let error = error {
                           print("Fehler bei der Spracherkennung: \(error.localizedDescription)")
                           return
                    }
                    
                    if let result = result {
                        let spokenText = result.bestTranscription.formattedString.lowercased()
                        self.onResult?(spokenText)
                    }
                }
                
                self.audioEngine.prepare()
                try? self.audioEngine.start()
            }
        }
    }
    
    func stopRecognition() {
          recognitionTask?.cancel()
          recognitionTask = nil
          request?.endAudio()
          request = nil
          
          if audioEngine.isRunning {
              audioEngine.stop()
              audioEngine.reset()
              audioEngine.inputNode.removeTap(onBus: 0)
          }
    }
  
    
}
