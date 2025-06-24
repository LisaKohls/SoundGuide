//
//  ContentView.swift
//  XR-App
//
//  Created by Lisa Kohls on 22.03.25.

/*
 Abstract:
 The applications main view.
 */

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
    
    @State private var showSettings = false

    
    var body: some View {
        NavigationStack {
            VStack {
                if appState.canEnterImmersiveSpace {
                    VStack {
                        Text("WELCOMETOSOUNDGUIDE".localized)
                            .font(.system(size: 25, weight:. bold))
                            .padding(30)
                        
                        if !showSpeechRecognizer{
                            Button("REPEATCONTENT_BTN".localized) {
                                print("Button Interaction: User tapped REPEAT CONTENT BUTTON", to: &logger)
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
                                StartRecordingButton(
                                    showSpeechRecognizer: $showSpeechRecognizer,
                                    showHomeButtons: $showHomeButtons,
                                    isSpeaking: $isSpeaking
                                )
                                
                                StartImmersiveSpaceBtn(
                                    immersiveSpaceIdentifier: immersiveSpaceIdentifier,
                                    showHomeButtons: $showHomeButtons,
                                    appState: appState,
                                    btnName: "UNKNOWNOBJECTS_BTN".localized
                                )
                                .disabled(isSpeaking)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        SpeechHelper.shared.speak(text: "LOOKFORUNKNOWNOBJECTS".localized) {
                                            isSpeaking = true
                                        }
                                    }
                                }
                            }
                        }
                        
                        if !appState.isImmersiveSpaceOpened {
                            if !showSpeechRecognizer && !showHomeButtons {
                                HStack {
                                    Button("REPEAT_BTN".localized) {
                                        print("Button Interaction: User tapped REPEAT BUTTON", to: &logger)
                                        showSpeechRecognizer = true
                                    }.padding()
                                        .accessibilityLabel("REPEAT_BTN".localized)
                                    
                                    StartImmersiveSpaceBtn(
                                        immersiveSpaceIdentifier: immersiveSpaceIdentifier,
                                        showHomeButtons: $showHomeButtons,
                                        appState: appState,
                                        btnName: "START_BTN".localized
                                    )
                                    
                                }.onAppear {
                                    SpeechHelper.shared.speak(text: "OBJECTFOUNDTEXT".localizedWithArgs(appState.recognizedText,"START_BTN".localized,"REPEAT_BTN".localized))
                                    
                                }.onChange(of: appState.recognizedText) {
                                    SpeechHelper.shared.speak(text: "OBJECTFOUNDTEXT".localizedWithArgs(appState.recognizedText,"START_BTN".localized,"REPEAT_BTN".localized))
                                }
                            } else if showSpeechRecognizer {
                                SpeechRecognizerView(viewModel: viewModel, showSpeechRecognizer: $showSpeechRecognizer){ newText in
                                    appState.recognizedText = newText
                                }
                            }
                            
                        } else {
                            Button("STOP_BTN".localized) {
                                print("Button Interaction: User tapped STOP BUTTON", to: &logger)
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
                                SpeechHelper.shared.stopSpeaking()
                                SpeechHelper.shared.speak(text: "VIEWLOADEDSUCCESSFULLY".localized)
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
                        print("Welcome to Soundguide. User test started with User 2. at: \(Date())", to: &logger)
                        // Required for better quality speech output
                        Task {
                            SpeechHelper.shared.preWarmSpeechEngine()
                            SpeechHelper.shared.speak(text: "WELCOMETEXT".localized) {
                                isSpeaking = true
                            }
                            SpeechHelper.shared.speak(text: "WELCOMETEXT2".localized){
                                isSpeaking = true
                            }
                        }
                    }.onDisappear() {
                        SpeechHelper.shared.stopSpeaking()
                    }
                }
            }
            .padding()
            .toolbar {
                if showHomeButtons && !showSpeechRecognizer && appState.canEnterImmersiveSpace {
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
            .sheet(isPresented: $showSettings) {
                SettingsView() 
            }
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
                if appState.allRequiredProvidersAreSupported {
                    await appState.requestWorldSensingAuthorization()
                }
            }
            .task {
                await appState.monitorSessionEvents()
            }
            
            
        }
        
    }
    
}
