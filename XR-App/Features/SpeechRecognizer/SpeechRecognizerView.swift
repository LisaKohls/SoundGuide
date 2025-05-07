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
    @Environment(\.dismiss) var dismiss
    @AccessibilityFocusState private var isFocused: Bool
    
    @State private var recognizedText: String = ""
    
    var onResult: (String) -> Void
    
    var body: some View {
        VStack {
            let recordedText = recognizedText.isEmpty ? "NORECORDEDOBJECT".localized : recognizedText
            Text(recordedText)
                .font(.headline)
                .onAppear {
                    viewModel.speak(text: "NORECORDEDOBJECT".localized)
            }
        }
        .onAppear {
                recognizedText = ""
                viewModel.onResult = { textResult in
                    if !textResult.isEmpty {
                        recognizedText = textResult
                        print("Erkannt recognized Text: \(recognizedText)")
                    }
                }
                viewModel.startRecognition()
        }
        .onChange(of: recognizedText) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showSpeechRecognizer = false
                viewModel.stopRecognition()
                onResult(recognizedText)
                dismiss()
            }
        }
        .onDisappear {
            viewModel.stopRecognition()
            viewModel.stopSpeaking()
        }
        .padding()
    }
}


