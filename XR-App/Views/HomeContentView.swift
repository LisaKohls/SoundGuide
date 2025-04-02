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
    
    @State private var showSpeechRecognizer = true
    
    var body: some View {
        Group {
            Text("Welcome to SoundGuide")
                .font(.system(size: 25, weight:. bold))
                .padding(30)
        }
        VStack {
            if appState.canEnterImmersiveSpace {
                VStack {
                    if !appState.isImmersiveSpaceOpened {
                            if !showSpeechRecognizer {
                            Text("Gesuchtes Objekt: \(appState.recognizedText)")
                                .font(.headline)
                                .padding()
                            
                            Button("Erneute Eingabe") {
                                appState.recognizedText = ""
                                showSpeechRecognizer = true
                            }.padding()
                            
                            Button("Starte das Tracking mit \(appState.referenceObjectLoader.enabledReferenceObjectsCount) Objekt(en)") {
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
                            } else {
                                SpeechRecognizerView(recognizedText: $appState.recognizedText, showSpeechRecognizer: $showSpeechRecognizer)
                            }
                    } else {
                        Button("Stop Tracking") {
                            Task {
                                await dismissImmersiveSpace()
                                appState.didLeaveImmersiveSpace()
                                appState.recognizedText = ""
                                showSpeechRecognizer = true
                            }
                        }
                        
                        if !appState.objectTrackingStartedRunning {
                            HStack {
                                ProgressView()
                                Text("Please wait until all reference objects have been loaded")
                            }
                        }
                    }
                    
                    Text(appState.isImmersiveSpaceOpened ?
                         "This leaves the immersive space." : "" )
                    
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .padding(.horizontal)
                    //.frame(minWidth: 400, minHeight: 300)
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
