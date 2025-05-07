//
//  ObjectsDetectionRealityView.swift
//  XR-App
//
//  Created by Lisa Kohls on 07.05.25.
//


import RealityKit
import ARKit
import SwiftUI
import RealityKitContent

@MainActor
struct ObjectsDetectionRealityView: View {
    
    @Bindable var appState: AppState
    var root = Entity()
    @StateObject var viewModel = SpeechRecognizerViewModel()
    
    var body: some View {
        RealityView { content in
            content.add(root)
            
            Task {
                let objectTracking = await appState.startTracking()
                guard let objectTracking else {
                    return
                }
                
                print("opened immersive detection space")
                for await anchorUpdate in objectTracking.anchorUpdates {
                    let anchor = anchorUpdate.anchor
                    var detectedObject = anchor.referenceObject.name.lowercased().replacingOccurrences(of: "_", with: " ")
                    
                    switch detectedObject {
                    case "tasse":
                        detectedObject = "MUG".localized
                    case "spices":
                        detectedObject = "SPICES".localized
                    case "erdbeertee":
                        detectedObject = "STRAWBERRYTEA".localized
                    case "zitronentee":
                        detectedObject = "LEMONTEA".localized
                    default:
                        break;
                    }
                    
                    print("detectedObject: \(detectedObject)")
                    
                    
                    if anchorUpdate.event == .added {
                        print("added detected Object: \(detectedObject)")
                        viewModel.speak(text: detectedObject)
                    }}
            }
            
        }
        .onAppear() {
            appState.isImmersiveSpaceOpened = true
        }
        .onDisappear() {
            appState.didLeaveImmersiveSpace()
        }
    }
}


