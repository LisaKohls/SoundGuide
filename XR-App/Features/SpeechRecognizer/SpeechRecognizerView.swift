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

    @Binding var showSpeechRecognizer: Bool
    @Binding var repeatSpeechRecognizer: Bool
    @Environment(\.dismiss) var dismiss
    @AccessibilityFocusState private var isFocused: Bool

    @State private var recognizedText: String = ""
    @State private var isListening = false
    @State private var startButton: Bool = true

    private let startRocordingBtn = "Aufnahme beginnen"
    private let beginRecordingHeading = "Beginne mit der Spracherkennung"
    private let noRecordedObject = "Nenne jetzt das gesuchte Objekt..."

    var onResult: (String) -> Void

    
    var body: some View {
        VStack {
            
            Text(beginRecordingHeading)
                .font(.title2)
                .padding()
                .accessibilityLabel(beginRecordingHeading)
                .onAppear {
                        viewModel.speak(text: beginRecordingHeading)
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
                        let recordedText = recognizedText.isEmpty && isListening ? noRecordedObject : recognizedText
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
                                        if !repeatSpeechRecognizer {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                                                viewModel.speak(text: startRocordingBtn)
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
                .onDisappear {
                    viewModel.stopRecognition()
                    isListening = false
                    repeatSpeechRecognizer = false
                }
                .padding()
        }
    }


