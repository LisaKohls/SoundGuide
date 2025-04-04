//
//  SpeechRecognizerView.swift
//  XR-App
//
//  Created by Lisa Kohls on 29.03.25.
//

import SwiftUI
import Speech

struct SpeechRecognizerView: View {
    
    @State private var recognizedText: String = ""
    @Binding var showSpeechRecognizer: Bool
    @Environment(\.dismiss) var dismiss
    
    @State private var isListening = false
    private let speechRecognizer = SpeechRecognizer()
    @State private var startButton: Bool = true
    var onResult: (String) -> Void
    
    var body: some View {
        VStack {
            
               Text("Beginne mit der Spracherkennung")
                   .font(.title3)
                   .padding()
            
                if !startButton {
                    Text(recognizedText.isEmpty && isListening ? "Aufnahme läuft..." : recognizedText)
                                       .font(.headline)
                }
               
               
               HStack {
                   Button(action: {
                       if isListening {
                           isListening = false
                           speechRecognizer.stopRecognition()
                           recognizedText = ""
                           startButton = true
                       } else {
                           recognizedText = ""
                           startButton = false
                           speechRecognizer.onResult = { textResult in
                               print("Erkannt: \(textResult)")
                               if !textResult.isEmpty {
                                   recognizedText = textResult
                               }
                           }
                           isListening = true
                           
                           speechRecognizer.startRecognition()
                       }
                   }) {
                       Text(isListening ? "Eingabe löschen" : "Starten")
                           .clipShape(Capsule())
                   }
                   
                   if isListening && !recognizedText.isEmpty {
                       Button("Submit") {
                          speechRecognizer.stopRecognition()
                          showSpeechRecognizer = false
                          onResult(recognizedText)
                          dismiss()
                      }.background(Color.gray.opacity(0.2))
                       .clipShape(Capsule())
                   }
                   
               }
           }
        .onDisappear {
            speechRecognizer.stopRecognition()
            isListening = false
        }
           .padding()
       }
   }

