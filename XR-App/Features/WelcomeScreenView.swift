//
//  WelcomeScreenView.swift
//  XR-App
//
//  Created by Lisa Salzer on 25.06.25.
//

import SwiftUI

struct WelcomeScreenView: View {
    let immersiveSpaceIdentifier: String
    @Bindable var appState: AppState
    
    let onStartObjectSearch: () -> Void
    let onStartUnknownSearch: () -> Void
    
    @Binding var isSpeaking: Bool
    @Binding var showSettings: Bool
    @Binding var showSpeechRecognizer: Bool
    @Binding var showHomeButtons: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("WELCOMETOSOUNDGUIDE".localized)
                    .font(.system(size: 25, weight: .bold))
                    .padding(30)
                
                if !showSpeechRecognizer {
                    Button("REPEATCONTENT_BTN".localized) {
                        SpeechHelper.shared.stopSpeaking()
                        let text = "REPEATCONTENT_HOME".localized
                        SpeechHelper.shared.speak(text: text)
                    }
                    .padding()
                    .accessibilityLabel("REPEATCONTENT_BTN".localized)
                }
                
                if showHomeButtons {
                    HStack {
                        OpenViewButton(
                            title: "STARTRECORDING_BTN".localized,
                            accessibilityLabel: "STARTRECORDING_BTN".localized,
                            action: {
                                onStartObjectSearch()
                            },
                            isSpeaking: $isSpeaking
                        )

                        OpenViewButton(
                            title: "UNKNOWNOBJECTS_BTN".localized,
                            accessibilityLabel: "UNKNOWNOBJECTS_BTN".localized,
                            action: {
                                onStartUnknownSearch()
                            },
                            isSpeaking: $isSpeaking
                        )
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            SpeechHelper.shared.speak(text: "LOOKFORUNKNOWNOBJECTS".localized) {
                                isSpeaking = true
                            }
                            SpeechHelper.shared.speak(text: "STARTRECORDINGINSTRUCTION".localizedWithArgs("STARTRECORDING_BTN".localized)) {
                                isSpeaking = true
                            }
                        }
                    }
                }
            }
            .foregroundStyle(.secondary)
            .font(.footnote)
            .padding(.horizontal)
            .toolbar {
                if showHomeButtons && !showSpeechRecognizer {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                        .accessibilityLabel("SETTINGS_BUTTON_LABEL".localized)
                    }
                }
            }
            .onAppear {
                SpeechHelper.shared.preWarmSpeechEngine()
                SpeechHelper.shared.speak(text: "WELCOMETEXT".localized) {
                    isSpeaking = true
                }
                SpeechHelper.shared.speak(text: "WELCOMETEXT2".localized) {
                    isSpeaking = true
                }
            }
            .onDisappear {
                SpeechHelper.shared.stopSpeaking()
            }
        }
    }
}
