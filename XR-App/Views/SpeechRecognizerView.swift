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
    @Environment(\.dismiss) var dismiss
    
    @State private var isListening = false
    private let speechRecognizer = SpeechRecognizer()
    
    var body: some View {
           VStack {
               Text("Say the name of the object")
                   .font(.title3)

               Text(recognizedText.isEmpty && isListening ? "Listening..." : recognizedText)
                   .font(.headline)
               
               HStack {
                   Button(action: {
                       if isListening {
                           speechRecognizer.stopRecognition()
                           isListening = false
                       } else {
        
                           speechRecognizer.onResult = { textResult in
                               print("Erkannt: \(textResult)")
                               if !textResult.isEmpty {
                                   recognizedText = textResult
                               }
                              
                               //speechRecognizer.stopRecognition()
                           }
                           
                           speechRecognizer.startRecognition()
                           isListening = true
                       }
                   }) {
                       Text(isListening ? "Stop" : "Start Listening")
                           .clipShape(Capsule())
                   }
                   
                   Button("Close") {
                       dismiss()
                   }
                   .background(Color.gray.opacity(0.2))
                   .clipShape(Capsule())
               }
           }
           .onDisappear {
               speechRecognizer.stopRecognition()
           }
           .padding()
       }
   }

