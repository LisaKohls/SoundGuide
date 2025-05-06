//
//  ContentView.swift
//  XR-App
//
//  Created by Lisa Kohls on 22.03.25.

import SwiftUI
import RealityKit

struct HomeContentView: View {
    let immersiveSpaceIdentifier: String
    @Bindable var appState: AppState
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @StateObject var viewModel = SpeechRecognizerViewModel()
    
    @State private var showSpeechRecognizer: Bool  = true
    @State private var repeatSpeechRecognizer: Bool = false
    
    var body: some View {
 
        VStack {
            if appState.canEnterImmersiveSpace {
                VStack {
                    Text("WELCOMETOSOUNDGUIDE".localized)
                        .font(.system(size: 25, weight:. bold))
                        .padding(30)
                    if !appState.isImmersiveSpaceOpened {
                        if !showSpeechRecognizer {
                            VStack {
                                Button("REPEAT_BTN".localized) {
                                    showSpeechRecognizer = true
                                    repeatSpeechRecognizer = true
                                }.padding()
                                    .accessibilityLabel("REPEAT_BTN".localized)
                                
                                
                                Button("REPEATCONTENT_BTN".localized) {
                                    viewModel.speak(text: "OBJECTFOUNDTEXT".localizedWithArgs(appState.recognizedText,"START_BTN".localized,"REPEAT_BTN".localized))
                                }.padding()
                                    .accessibilityLabel("REPEATCONTENT_BTN".localized)
                                
                                Button("START_BTN".localized) {
                                    Task {
                                        switch await openImmersiveSpace(id: immersiveSpaceIdentifier) {
                                        case .opened:
                                            break
                                        case .error:
                                            print("An error occurred when trying to open the immersive space \(immersiveSpaceIdentifier)")
                                        case .userCancelled:
                                            print("The user declined opening immersive space \(immersiveSpaceIdentifier)")
                                        @unknown default:
                                            break
                                        }
                                    }
                                }
                                .disabled(!appState.canEnterImmersiveSpace || appState.referenceObjectLoader.enabledReferenceObjectsCount == 0)
                                .accessibilityLabel("START_BTN".localized)
                            }.onAppear {
                                viewModel.speak(text: "OBJECTFOUNDTEXT".localizedWithArgs(appState.recognizedText,"START_BTN".localized,"STOP_BTN".localized))
                            }.onDisappear {
                                viewModel.stopSpeaking()
                            }
                        } else {
                            SpeechRecognizerView(viewModel: viewModel, showSpeechRecognizer: $showSpeechRecognizer, repeatSpeechRecognizer: $repeatSpeechRecognizer){ newText in
                                appState.recognizedText = newText
                            }
                        }
                        
                    } else {
                        
                        Button("STOP_BTN".localized) {
                            Task {
                                await dismissImmersiveSpace()
                                appState.didLeaveImmersiveSpace()
                                appState.recognizedText = ""
                                repeatSpeechRecognizer = false
                                showSpeechRecognizer = true
                            }
                        }.accessibilityLabel("STOP_BTN".localized)
                            .onAppear {
                                viewModel.speak(text: "OBJECTFOUNDSHORT".localizedWithArgs("STOP_BTN".localized, "STOP".localized))
                            }
                           
                        
                        Button("REPEATCONTENT_BTN".localized) {
                            viewModel.speak(text: "OBJECTFOUNDSHORT".localizedWithArgs("STOP_BTN".localized, "STOP".localized))
                        }.padding()
                            .accessibilityLabel("REPEATCONTENT_BTN".localized)
                        
                        
                        if !appState.objectTrackingStartedRunning {
                            HStack {
                                Text("LOADOBJECTSTEXT".localized)
                                    .accessibilityLabel("LOADOBJECTSTEXT".localized)
                            }
                        }
                    }
                }
                .foregroundStyle(.secondary)
                .font(.footnote)
                .padding(.horizontal)
                .onAppear {
                    // For higher quality speech output
                    viewModel.preWarmSpeechEngine()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        viewModel.speak(text: "WELCOMETEXT".localized)
                    }
                    repeatSpeechRecognizer = false
                }
            }
        }
        .padding()
        .onChange(of: scenePhase, initial: true) {
            print("Scene phase: \(scenePhase)")
            if scenePhase == .active {
                Task {
                    // When returning from the background, check if the authorization has changed.
                    await appState.queryWorldSensingAuthorization()
                }
            } else {
                if appState.isImmersiveSpaceOpened {
                    Task {
                        await dismissImmersiveSpace()
                        appState.didLeaveImmersiveSpace()
                    }
                }
            }
        }
        .onChange(of: appState.providersStoppedWithError, { _, providersStoppedWithError in
            // Immediately close the immersive space if an error occurs.
            if providersStoppedWithError {
                if appState.isImmersiveSpaceOpened {
                    Task {
                        await dismissImmersiveSpace()
                        appState.didLeaveImmersiveSpace()
                    }
                }
                
                appState.providersStoppedWithError = false
            }
        })
        .task {
            // Ask for authorization before a person attempts to open the immersive space.
            // This gives the app opportunity to respond gracefully if authorization isn't granted.
            if appState.allRequiredProvidersAreSupported {
                await appState.requestWorldSensingAuthorization()
            }
        }
        .task {
            // Start monitoring for changes in authorization, in case a person brings the
            // Settings app to the foreground and changes authorizations there.
            await appState.monitorSessionEvents()
        }
        
        
    }
}

#Preview(windowStyle: .automatic) {
    HomeContentView(immersiveSpaceIdentifier: "ObjectTracking", appState: AppState())
}
