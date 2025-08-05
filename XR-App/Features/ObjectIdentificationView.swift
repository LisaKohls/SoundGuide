//
//  ObjectIdentificationView.swift
//  XR-App
//
//  Created by Lisa Kohls on 25.06.25.
//  Reference: [2] https://github.com/dilmerv/VisionOSObjectTrackingDemo
//

import SwiftUI
import RealityKit

struct ObjectIdentificationView: View {
    let immersiveSpaceIdentifier: String
    @Bindable var appState: AppState
    var onExit: () -> Void

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var hasOpenedSpace = false

    var body: some View {
        VStack {
            Text("WELCOMETOSOUNDGUIDE".localized)
                .font(.system(size: 25, weight: .bold))
                .padding(30)
            // [2]
            if appState.isImmersiveSpaceOpened {
                Button("STOP_BTN".localized) {
                    SpeechHelper.shared.stopSpeaking()
                    Task {
                        await dismissImmersiveSpace()
                        appState.didLeaveImmersiveSpace()
                        appState.recognizedText = ""
                        onExit()
                    }
                }
                .accessibilityLabel("STOP_BTN".localized)
                .onAppear {
                    SpeechHelper.shared.speak(text: "START_STOP_TRACKING_BTN".localizedWithArgs("STOP_BTN".localized,"STOP".localized))
                }
                .padding()
                
            } else {
                // Charging indicator
                ProgressView("STARTING_IMMERSIVE...".localized)
                    .padding()
            }
        }
        .foregroundStyle(.secondary)
        .font(.footnote)
        .padding(.horizontal)
        .onAppear {
            startImmersiveSpaceIfNeeded()
        }
        .onDisappear {
            SpeechHelper.shared.stopSpeaking()
        }
    }

    private func startImmersiveSpaceIfNeeded() {
        // [2]
        Task {
            appState.realityView = "ObjectIdentificationView"
            let result = await openImmersiveSpace(id: immersiveSpaceIdentifier)
            if case .opened = result {
                appState.isImmersiveSpaceOpened = true
            }
        }
    }
}




