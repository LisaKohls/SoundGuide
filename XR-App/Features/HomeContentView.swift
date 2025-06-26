//
//  ContentView.swift
//  XR-App
//
//  Created by Lisa Kohls on 22.03.25.
//  Reference: https://github.com/dilmerv/VisionOSObjectTrackingDemo

/*
 Abstract:
 The applications main view.
 */


import SwiftUI
import RealityKit

struct HomeContentView: View {
    let immersiveSpaceIdentifier: String
    @Bindable var appState: AppState

    @State private var currentScreen: AppScreen = .welcome
    @State private var showSpeechRecognizer: Bool = false
    @State private var isSpeaking: Bool = true
    @State private var showSettings: Bool = false

    var body: some View {
        ZStack {
            switch currentScreen {
            case .welcome:
                WelcomeScreenView(
                    immersiveSpaceIdentifier: immersiveSpaceIdentifier,
                    appState: appState,
                    onStartObjectSearch: {
                        currentScreen = .searchForObjects
                    },
                    onStartUnknownSearch: {
                        currentScreen = .objectIdentification
                    },
                    isSpeaking: $isSpeaking,
                    showSettings: $showSettings,
                    showSpeechRecognizer: $showSpeechRecognizer
                )
            case .objectIdentification:
                ObjectIdentificationView(
                    immersiveSpaceIdentifier: immersiveSpaceIdentifier,
                    appState: appState,
                    onExit: {
                        currentScreen = .welcome
                    }
                )
            case .searchForObjects:
                SearchForObjectsView(
                    immersiveSpaceIdentifier: immersiveSpaceIdentifier,
                    appState: appState,
                    onExit: {
                        currentScreen = .welcome
                    }
                )
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
