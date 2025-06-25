//
//  ObjectIdentificationView.swift
//  XR-App
//
//  Created by Lisa Salzer on 25.06.25.
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
                .padding()
                
            } else {
                // Ladeanzeige
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
        print("🟩 current view:", appState.realityView)

        Task {
            appState.realityView = "ObjectIdentificationView"
            let result = await openImmersiveSpace(id: immersiveSpaceIdentifier)
            if case .opened = result {
                appState.isImmersiveSpaceOpened = true
            }
        }
    }
}




