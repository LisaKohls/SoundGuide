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
    
    @State private var showSpeechRecognizer: Bool  = false
    @State private var showLookForUnknownObjectsView: Bool  = false
    @State private var showHomeButtons: Bool  = true
    @State private var isSpeaking = true
  
    var body: some View {
 
        VStack {
            if appState.canEnterImmersiveSpace {
                VStack {
                    Text("WELCOMETOSOUNDGUIDE".localized)
                        .font(.system(size: 25, weight:. bold))
                        .padding(30)
                    
                    if !showSpeechRecognizer{
                        Button("REPEATCONTENT_BTN".localized) {
                            let tempContentOnView = {
                                if showHomeButtons {
                                    return "REPEATCONTENT_HOME".localized
                                } else if !appState.isImmersiveSpaceOpened && !showSpeechRecognizer && !showHomeButtons {
                                    return "OBJECTFOUNDTEXT".localizedWithArgs(appState.recognizedText, "START_BTN".localized, "REPEAT_BTN".localized)
                                } else if appState.isImmersiveSpaceOpened {
                                    return "START_STOP_TRACKING_BTN".localizedWithArgs("STOP_BTN".localized,"STOP".localized)
                                } else {
                                    return "WELCOMETOSOUNDGUIDE".localized
                                }
                            }()
                            
                            SpeechHelper.shared.speak(text: tempContentOnView)
                        }
                        .padding()
                        .accessibilityLabel("REPEATCONTENT_BTN".localized)
                    }
                    
                    //Home Buttons, Start Recording/ Start looking for unknown objects
                    if showHomeButtons {
                        HStack{
                            Button(action: {
                                showSpeechRecognizer = true
                                showHomeButtons = false
                            }) {
                                Text("STARTRECORDING_BTN".localized)
                                    .clipShape(Capsule())
                                    .accessibilityLabel("STARTRECORDING_BTN".localized)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                            SpeechHelper.shared.speak(text: "STARTRECORDINGINSTRUCTION".localizedWithArgs("STARTRECORDING_BTN".localized)) {
                                                isSpeaking = false
                                            }
                                        }
                                    }
                            }.disabled(isSpeaking)
                            
                            Button(action: {
                                //show searchObjectsView
                                Task {
                                    appState.realityView = "UnknownObjectDetection"
                                        switch await openImmersiveSpace(id: immersiveSpaceIdentifier) {
                                        case .opened:
                                            print("UnknownObjectDetection Immersive Space opened")
                                        case .error:
                                            print("Error opening UnknownObjectDetection Immersive Space")
                                        case .userCancelled:
                                            print("User cancelled opening")
                                        @unknown default:
                                            break
                                        }
                                    showHomeButtons = false
                                    }
                            }) {
                                Text("UNKNOWNOBJECTS_BTN".localized)
                                    .clipShape(Capsule())
                                    .accessibilityLabel("UNKNOWNOBJECTS_BTN".localized)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            SpeechHelper.shared.speak(text: "LOOKFORUNKNOWNOBJECTS".localized) {
                                                isSpeaking = true
                                            }
                                        }
                                    }
                            }.disabled(isSpeaking)
                        }
                    }
                    
                    if !appState.isImmersiveSpaceOpened {
                        if !showSpeechRecognizer && !showHomeButtons {
                            VStack {
                                Button("REPEAT_BTN".localized) {
                                    showSpeechRecognizer = true
                                }.padding()
                                    .accessibilityLabel("REPEAT_BTN".localized)
                                
                                HStack {
                                    
                                    Button("HOME_BTN".localized) {
                                        showHomeButtons = true
                                    }.padding()
                                    .accessibilityLabel("HOME_BTN".localized)
                                    
                                    Button("START_BTN".localized) {
                                        Task {
                                            appState.realityView = immersiveSpaceIdentifier
                                            switch await openImmersiveSpace(id: immersiveSpaceIdentifier) {
                                            case .opened:
                                                showHomeButtons = false
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
                                }
                                
                            }.onAppear {
                                SpeechHelper.shared.speak(text: "OBJECTFOUNDTEXT".localizedWithArgs(appState.recognizedText,"START_BTN".localized,"REPEAT_BTN".localized, "HOME_BTN".localized))
                               
                            }.onChange(of: appState.recognizedText) {
                                    SpeechHelper.shared.speak(text: "OBJECTFOUNDTEXT".localizedWithArgs(appState.recognizedText,"START_BTN".localized,"REPEAT_BTN".localized, "HOME_BTN".localized))
                            }
                            .onDisappear {
                                SpeechHelper.shared.stopSpeaking()
                            }
                        } else if showSpeechRecognizer {
                            SpeechRecognizerView(viewModel: viewModel, showSpeechRecognizer: $showSpeechRecognizer){ newText in
                                appState.recognizedText = newText
                            }
                        }
                        
                    } else {
                        Button("STOP_BTN".localized) {
                            SpeechHelper.shared.stopSpeaking()
                            Task {
                                await dismissImmersiveSpace()
                                appState.didLeaveImmersiveSpace()
                                appState.recognizedText = ""
                                showHomeButtons = true
                            }
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
                .foregroundStyle(.secondary)
                .font(.footnote)
                .padding(.horizontal)
                .onAppear {
                    // Required for better quality speech output
                    Task {
                        SpeechHelper.shared.preWarmSpeechEngine()
                        SpeechHelper.shared.speak(text: "WELCOMETEXT".localized) {
                            isSpeaking = true
                        }
                    }
                }.onDisappear() {
                    SpeechHelper.shared.stopSpeaking()
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
        .onChange(of: appState.didFinishObjectDetection) { _, didFinish in
            if didFinish {
                
                Task {
                    await dismissImmersiveSpace()
                    appState.didLeaveImmersiveSpace()
                    appState.recognizedText = ""
                    showHomeButtons = true
                    appState.didFinishObjectDetection = false
                }
            }
        }
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

