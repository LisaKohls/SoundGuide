//
//  SpeechRecognizerView.swift
//  XR-App
//
//  Created by Lisa Kohls on 29.03.25.
//

import SwiftUI
import Speech

struct SpeechRecognizerView: View {
    var viewModel: SpeechRecognizerViewModel 
    
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
                .onAppear {
                        viewModel.speak(text: "Beginne mit der Spracherkennung")
                }
                    
                    if !startButton {
                        let startBtnText = recognizedText.isEmpty && isListening ? "Aufnahme läuft..." : recognizedText
                        Text(startBtnText)
                            .font(.headline)
                            .onAppear {
                                    viewModel.speak(text: startBtnText)
                            }.onChange(of: startBtnText) {
                                viewModel.speak(text: startBtnText)
                            }
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
                            let btnText = isListening ? "Eingabe löschen Button" : "Start Button"
                            Text(btnText)
                                .clipShape(Capsule())
                                .accessibilityLabel(btnText)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                        viewModel.speak(text: btnText)
                                    }
                                }.onChange(of: btnText){
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        viewModel.speak(text: btnText)
                                    }
                                }
                        }
                        
                        
                        if isListening && !recognizedText.isEmpty {
                            Button("Einreichen Button") {
                                speechRecognizer.stopRecognition()
                                showSpeechRecognizer = false
                                onResult(recognizedText)
                                dismiss()
                            }.background(Color.gray.opacity(0.2))
                                .clipShape(Capsule())
                                .accessibilityLabel("Einreichen Button")
                                .onAppear {
                                     viewModel.speak(text: "Einreichen Button")
                                }
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


