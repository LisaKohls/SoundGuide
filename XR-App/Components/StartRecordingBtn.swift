//
//  StartRecordingBtn.swift
//  XR-App
//
//  Created by Lisa Kohls on 08.05.25.
//

import SwiftUICore
import SwiftUI

struct StartRecordingButton: View {
    @Binding var showSpeechRecognizer: Bool
    @Binding var showHomeButtons: Bool
    @Binding var isSpeaking: Bool
    
    var body: some View {
        Button(action: {
            print("Button Interaction: User tapped start recording button", to: &logger)
            showSpeechRecognizer = true
            showHomeButtons = false
        }) {
            Text("STARTRECORDING_BTN".localized)
                .clipShape(Capsule())
                .accessibilityLabel("STARTRECORDING_BTN".localized)
        }
        .disabled(isSpeaking)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                SpeechHelper.shared.speak(text: "STARTRECORDINGINSTRUCTION".localizedWithArgs("STARTRECORDING_BTN".localized)) {
                    isSpeaking = false
                }
            }
        }
    }
}
