//
//  XR_AppApp.swift
//  XR-App
//
//  Created by Lisa Kohls on 22.03.25.
//  Reference: [3] https://developer.apple.com/documentation/visionos/creating-your-first-visionos-app

import SwiftUI

@main
struct XR_AppApp: App {
    
    @State private var appState = AppState()
    
    init() {
        AppDefaults.register() // default settings
    }
    
    var body: some Scene {
        WindowGroup {
            HomeContentView(immersiveSpaceIdentifier: "ObjectTracking", appState: appState)
                .task {
                    if appState.allRequiredProvidersAreSupported {
                        await appState.referenceObjectLoader.loadBuiltInReferenceObjects()
                    }
                }
        }
        .defaultSize(CGSize(width: 600, height: 400))
        
        ImmersiveSpace(id: "ObjectTracking") {
            ObjectsDetectionRealityView(appState: appState)
        }
        
    }
}
