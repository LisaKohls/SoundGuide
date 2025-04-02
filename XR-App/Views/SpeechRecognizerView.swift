//
//  SpeechRecognizerView.swift
//  XR-App
//
//  Created by Lisa Kohls on 29.03.25.
//

import SwiftUI
import Speech

struct SpeechRecognizerView: View {
    
    @Binding var recognizedText: String
    @Binding var showSpeechRecognizer: Bool
    @Environment(\.dismiss) var dismiss
    
    @State private var isListening = false
    private let speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        VStack {
            
               Text("Beginne mit der Spracherkennung")
                   .font(.title3)

               Text(recognizedText.isEmpty && isListening ? "Listening..." : recognizedText)
                   .font(.headline)
               
               HStack {
                   Button(action: {
                       if isListening {
                           speechRecognizer.stopRecognition()
                           recognizedText = ""
                           isListening = false
                       } else {
                           speechRecognizer.startRecognition()
                           speechRecognizer.onResult = { textResult in
                               print("Erkannt: \(textResult)")
                               if !textResult.isEmpty {
                                   recognizedText = textResult
                               }
                           }
                           isListening = true
                       }
                   }) {
                       Text(isListening ? "Eingabe löschen" : "Starten")
                           .clipShape(Capsule())
                   }
                   
                   if isListening && !recognizedText.isEmpty {
                       Button("Submit") {
                          showSpeechRecognizer = false
                          //speechRecognizer.stopRecognition()
                          dismiss()
                      }.background(Color.gray.opacity(0.2))
                       .clipShape(Capsule())
                   }
                   
               }
           }
           .onDisappear {
               speechRecognizer.stopRecognition()
           }
           .padding()
       }
   }

