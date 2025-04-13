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
    @AccessibilityFocusState private var isFocused: Bool
    var onResult: (String) -> Void
    
    var body: some View {
        VStack {
            
            Text("Beginne mit der Spracherkennung")
                .font(.title3)
                .padding()
                .accessibilityLabel("Beginne mit der Spracherkennung")
                    
                    if !startButton {
                        let startBtnText = recognizedText.isEmpty && isListening ? "Aufnahme läuft..." : recognizedText
                        Text(startBtnText)
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
                                    
                                    if !textResult.isEmpty && !textResult.contains("ein") && !textResult.contains("klicken") {
                                        recognizedText = textResult
                                        print("Erkannt recognized Text: \(recognizedText)")
                                    }
                                }
                                isListening = true
                                
                                speechRecognizer.startRecognition()
                            }
                        }) {
                            let btnText = isListening ? "Eingabe löschen" : "Starten"
                            Text(btnText)
                                .clipShape(Capsule())
                                .accessibilityLabel(isListening ? "Eingabe löschen" : "Starten")
                        }
                        
                        
                        if isListening && !recognizedText.isEmpty {
                            Button("Einreichen") {
                                speechRecognizer.stopRecognition()
                                showSpeechRecognizer = false
                                onResult(recognizedText)
                                dismiss()
                            }.background(Color.gray.opacity(0.2))
                                .clipShape(Capsule())
                                .accessibilityLabel("Einreichen")
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


