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
    
    private let repeatBtn = "Erneut eingeben"
    private let repeatContentBtn = "Inhalte erneut vorlesen"
    private let startBtn = "Suche starten"
    private let stopBtn = "Suche beenden"
    private let text = "Das Tracking ist gestartet, bewege den Kopf und bewege dich leicht um die Objekte zu finden."
    private let LoadObjectsText = "Objekte werden geladen."
    private let welcomeText = "Willkommen zu SoundGuide. Das System ließt dir die möglichen Aktionen vor um das Object Tracking zu verwenden. Um einen Batten zu klicken, sage den Namen des vorgelesenen Batten und klicken dazu. Falls du erneut die Inhalte vorgelesen bekommen möchtest, sage Inhalte erneut vorlesen klicken."
    
    var body: some View {
        Group {
            Text("Willkommen zu SoundGuide")
                .font(.system(size: 25, weight:. bold))
                .padding(30)
                .onAppear {
                    //viewModel.speak(text: welcomeText)
                }
        }
        
        VStack {
            if appState.canEnterImmersiveSpace {
                VStack {
                    if !appState.isImmersiveSpaceOpened {
                            if !showSpeechRecognizer {
                            Text("Gesuchtes Objekt: \(appState.recognizedText)")
                                .font(.headline)
                                .padding()
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        viewModel.speak(text: "Das gesuchte Objekt ist \(appState.recognizedText)")
                                    }
                             }
                            
                            Button(repeatBtn) {
                                showSpeechRecognizer = true
                                repeatSpeechRecognizer = true
                            }.padding()
                                 .accessibilityLabel(repeatBtn)
                                 .onAppear {
                                     viewModel.speak(text: repeatBtn)
                            }
                            
                            Button(repeatContentBtn) {
                                viewModel.speak(text: "Gesuchtes Objekt: \(appState.recognizedText), \(repeatBtn), \(startBtn)")
                            }.padding()
                             .accessibilityLabel(repeatContentBtn)
                               
                                
                            
                            Button(startBtn) {
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
                            .accessibilityLabel(startBtn)
                            .onAppear {
                                viewModel.speak(text: startBtn)
                            }
                            } else {
                                SpeechRecognizerView(viewModel: viewModel, showSpeechRecognizer: $showSpeechRecognizer, repeatSpeechRecognizer: $repeatSpeechRecognizer){ newText in
                                    appState.recognizedText = newText
                                }
                            }
                    } else {
                        
                       
                        Button(stopBtn) {
                            Task {
                                await dismissImmersiveSpace()
                                appState.didLeaveImmersiveSpace()
                                appState.recognizedText = ""
                                showSpeechRecognizer = true
                            }
                        }.accessibilityLabel(stopBtn)
                            .onAppear {
                                viewModel.speak(text: stopBtn)
                            }
                        
                        Button(repeatContentBtn) {
                            viewModel.speak(text: stopBtn)
                        }.padding()
                         .accessibilityLabel(repeatContentBtn)
                        
                        
                        if !appState.objectTrackingStartedRunning {
                            HStack {
                                Text(LoadObjectsText)
                                .accessibilityLabel(LoadObjectsText)
                                .onAppear {
                                    viewModel.speak(text: LoadObjectsText)
                                }
                            }
                        }else{
                            
                            Text(text)
                            .accessibilityLabel(text)
                            .onAppear {
                                viewModel.speak(text: text)
                            }
                        }
                    }
                }
                .foregroundStyle(.secondary)
                .font(.footnote)
                .padding(.horizontal)
            }
        }
        .padding()
        .onAppear(){
            repeatSpeechRecognizer = false
        }
        .onChange(of: scenePhase, initial: true) {
            print("Scene phase: \(scenePhase)")
            if scenePhase == .active {
                Task {
                    // When returning from the background, check if the authorization has changed.
                    await appState.queryWorldSensingAuthorization()
                }
            } else {
                // Make sure to leave the immersive space if this view is no longer active
                // - such as when a person closes this view - otherwise they may be stuck
                // in the immersive space without the controls this view provides.
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
