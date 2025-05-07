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
    
    var body: some View {
 
        VStack {
            if appState.canEnterImmersiveSpace {
                VStack {
                    Text("WELCOMETOSOUNDGUIDE".localized)
                        .font(.system(size: 25, weight:. bold))
                        .padding(30)
                    
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
                                        //3.5s
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                                            viewModel.speak(text: "STARTRECORDINGINSTRUCTION".localizedWithArgs("STARTRECORDING_BTN".localized))
                                        }
                                    }
                            }
                            
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
                                        //3.5s
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                                            viewModel.speak(text: "LOOKFORUNKNOWNOBJECTS".localized)
                                        }
                                    }
                            }
                        }.onDisappear {
                            viewModel.stopSpeaking()
                        }
                    }
                    
                    if !appState.isImmersiveSpaceOpened {
                        if !showSpeechRecognizer && !showHomeButtons {
                            VStack {
                                Button("REPEAT_BTN".localized) {
                                    showSpeechRecognizer = true
                                }.padding()
                                    .accessibilityLabel("REPEAT_BTN".localized)
                                
                                
                                Button("REPEATCONTENT_BTN".localized) {
                                    viewModel.speak(text: "OBJECTFOUNDTEXT".localizedWithArgs(appState.recognizedText,"START_BTN".localized,"REPEAT_BTN".localized))
                                }.padding()
                                    .accessibilityLabel("REPEATCONTENT_BTN".localized)
                                
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
                                viewModel.speak(text: "OBJECTFOUNDTEXT".localizedWithArgs(appState.recognizedText,"START_BTN".localized,"REPEAT_BTN".localized, "HOME_BTN".localized))
                            }.onChange(of: appState.recognizedText) {
                                viewModel.speak(text: "OBJECTFOUNDTEXT".localizedWithArgs(appState.recognizedText,"START_BTN".localized,"REPEAT_BTN".localized, "HOME_BTN".localized))
                            }
                            .onDisappear {
                                viewModel.stopSpeaking()
                            }
                        } else if showSpeechRecognizer {
                            SpeechRecognizerView(viewModel: viewModel, showSpeechRecognizer: $showSpeechRecognizer){ newText in
                                appState.recognizedText = newText
                            }
                        }
                        
                    } else {
                 
                        Button("STOP_BTN".localized) {
                            Task {
                                await dismissImmersiveSpace()
                                appState.didLeaveImmersiveSpace()
                                appState.recognizedText = ""
                                showHomeButtons = true
                            }
                        }
                        .accessibilityLabel("STOP_BTN".localized)
                        .onAppear {
                             viewModel.speak(text: "START_STOP_TRACKING_BTN".localizedWithArgs("STOP_BTN".localized,"STOP".localized))
                       }
                           
                        
                        Button("REPEATCONTENT_BTN".localized) {
                            viewModel.speak(text: "START_STOP_TRACKING_BTN".localizedWithArgs("STOP_BTN".localized, "STOP".localized))
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
                    /* For higher quality speech output
                    viewModel.preWarmSpeechEngine()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        viewModel.speak(text: "WELCOMETEXT".localized)
                    }*/
                }.onDisappear() {
                    viewModel.stopSpeaking()
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

