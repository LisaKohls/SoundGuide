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
    @Binding var repeatSpeechRecognizer: Bool
    @Environment(\.dismiss) var dismiss
    
    @State private var isListening = false
    @State private var startButton: Bool = true
    @AccessibilityFocusState private var isFocused: Bool
    private let startRocordingBtn =  "Aufnahme beginnen"
    var onResult: (String) -> Void
    
    var body: some View {
        VStack {
            
            Text("Beginne mit der Spracherkennung")
                .font(.title3)
                .padding()
                .accessibilityLabel("Beginne mit der Spracherkennung")
                .onAppear {
                    print("repeatSpeechRecognizer: \(repeatSpeechRecognizer)")
                        viewModel.speak(text: "Beginne mit der Spracherkennung")
                        if repeatSpeechRecognizer {
                            recognizedText = ""
                            startButton = false
                            viewModel.onResult = { textResult in
                                
                                if !textResult.isEmpty && !textResult.contains("ein") && !textResult.contains("klicken") {
                                    recognizedText = textResult
                                    print("Erkannt recognized Text: \(recognizedText)")
                                }
                            }
                            isListening = true
                            viewModel.startRecognition()
                    }
                }
                    
                if !startButton {
                        let recordedText = recognizedText.isEmpty && isListening ? "Nenne jetzt das gesuchte Objekt..." : recognizedText
                        Text(recordedText)
                            .font(.headline)
                            .onAppear {
                               viewModel.speak(text: recordedText)
                            }.onChange(of: recordedText) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    showSpeechRecognizer = false
                                    viewModel.stopRecognition()
                                    onResult(recognizedText)
                                    dismiss()
                                }
                            }
                    }
                    
                    
                    HStack {
                        if !isListening {
                            Button(action: {
                                recognizedText = ""
                                startButton = false
                                viewModel.onResult = { textResult in
                                    if !textResult.isEmpty && !textResult.contains("ein") && !textResult.contains("klicken") {
                                        recognizedText = textResult
                                        print("Erkannter Text: \(recognizedText)")
                                    }
                                }
                                isListening = true
                                
                                viewModel.startRecognition()
                            }
                            ) {
                                Text(startRocordingBtn)
                                    .clipShape(Capsule())
                                    .accessibilityLabel(startRocordingBtn)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                                            viewModel.speak(text: startRocordingBtn)
                                        }
                                    }
                            }
                        }
                    }
                }
                .onDisappear {
                    viewModel.stopRecognition()
                    isListening = false
                }
                .padding()
        }
    }


