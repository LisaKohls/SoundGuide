//
//  StartImmersiveSpaceBtn.swift
//  XR-App
//
//  Created by Lisa Kohls on 08.05.25.
//

import SwiftUI

struct StartImmersiveSpaceBtn: View {
    let immersiveSpaceIdentifier: String
    @Binding var showHomeButtons: Bool
    @Bindable var appState: AppState
    let btnName: String
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    var body: some View {
        Button(btnName) {
            print("Button Interaction: User tapped \(btnName) to open immersive space", to: &logger)
            Task {
                appState.realityView = btnName
                switch await openImmersiveSpace(id: immersiveSpaceIdentifier) {
                case .opened:
                    showHomeButtons = false
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
        .accessibilityLabel(btnName)
    }
}

