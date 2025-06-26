//
//  SearchForObjectsView.swift
//  XR-App
//
//  Created by Lisa Salzer on 25.06.25.
//

import SwiftUI
import RealityKit

struct SearchForObjectsView: View {
    let immersiveSpaceIdentifier: String
    @Bindable var appState: AppState
    var onExit: () -> Void

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @StateObject private var viewModel = SpeechRecognizerViewModel()
    @State private var showSpeechRecognizer = true

    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Text("WELCOMETOSOUNDGUIDE".localized)
                        .font(.system(size: 25, weight: .bold))
                        .padding(30)

                    if !showSpeechRecognizer {
                        Button("REPEATCONTENT_BTN".localized) {
                            let text: String
                            if appState.isImmersiveSpaceOpened {
                                text = "START_STOP_TRACKING_BTN".localizedWithArgs("STOP_BTN".localized, "STOP".localized)
                            } else {
                                text = "OBJECTFOUNDTEXT".localizedWithArgs(appState.recognizedText, "START_BTN".localized, "REPEAT_BTN".localized)
                            }
                            SpeechHelper.shared.speak(text: text)
                        }
                        .padding()
                        .accessibilityLabel("REPEATCONTENT_BTN".localized)
                    }

                    if !appState.isImmersiveSpaceOpened {
                        if !showSpeechRecognizer && !appState.showWelcomeView {
                            HStack {
                                Button("REPEAT_BTN".localized) {
                                    SpeechHelper.shared.stopSpeaking()
                                    showSpeechRecognizer = true
                                }
                                .padding()
                                .accessibilityLabel("REPEAT_BTN".localized)

                                Button("START_BTN".localized) {
                                    SpeechHelper.shared.stopSpeaking()
                                    Task {
                                        appState.realityView = "SearchForObjectsView" 
                                        let result = await openImmersiveSpace(id: immersiveSpaceIdentifier)
                                        if result == .opened {
                                            appState.isImmersiveSpaceOpened = true
                                        }
                                    }
                                }
                                .accessibilityLabel("START_BTN".localized)
                            }
                            .onAppear {
                                SpeechHelper.shared.speak(text: "OBJECTFOUNDTEXT".localizedWithArgs(appState.recognizedText, "START_BTN".localized, "REPEAT_BTN".localized))
                            }
                            .onChange(of: appState.recognizedText) {
                                SpeechHelper.shared.speak(text: "OBJECTFOUNDTEXT".localizedWithArgs(appState.recognizedText, "START_BTN".localized, "REPEAT_BTN".localized))
                            }
                        } else if showSpeechRecognizer {
                            SpeechRecognizerView(viewModel: viewModel, showSpeechRecognizer: $showSpeechRecognizer) { newText in
                                appState.recognizedText = newText
                                showSpeechRecognizer = false
                            }
                        }
                    } else {
                        Button("STOP_BTN".localized) {
                            appState.didFinishObjectDetection = true
                        }
                        .accessibilityLabel("STOP_BTN".localized)
                        .onAppear {
                            SpeechHelper.shared.speak(text: "START_STOP_TRACKING_BTN".localizedWithArgs("STOP_BTN".localized,"STOP".localized))
                        }

                        if !appState.objectTrackingStartedRunning {
                            HStack {
                                Text("LOADOBJECTSTEXT".localized)
                                    .accessibilityLabel("LOADOBJECTSTEXT".localized)
                            }
                        }
                    }
                }
                .onAppear {
                    appState.showWelcomeView = false
                }
                .foregroundStyle(.secondary)
                .font(.footnote)
                .padding(.horizontal)
            }
        }
        .onChange(of: appState.didFinishObjectDetection) { _, didFinish in
            if didFinish {
                Task {
                    await dismissImmersiveSpace()
                    appState.didLeaveImmersiveSpace()
                    appState.recognizedText = ""
                    appState.showWelcomeView = true
                    onExit()
                    appState.didFinishObjectDetection = false
                }
            }
        }
    }
}


