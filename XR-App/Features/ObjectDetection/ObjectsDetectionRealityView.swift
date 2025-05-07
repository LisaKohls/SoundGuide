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
    @StateObject var objectDetectionRealityViewModel = ObjectsDetectionRealityViewModel()
    @State private var objectVisualizations: [UUID: ObjectAnchorVisualization] = [:]
    
    
    var body: some View {
        RealityView { content in
            content.add(root)
            
            let detectionView = appState.realityView == "UnknownObjectDetection"
            let trackingView = appState.realityView == "ObjectTracking"
            
            if detectionView { objectDetectionRealityViewModel.makeHandEntities(in: content) }
       
            Task {
                let objectTracking = await appState.startTracking()
                guard let objectTracking else {
                    return
                }
                
                for await anchorUpdate in objectTracking.anchorUpdates {
                    let anchor = anchorUpdate.anchor
                    let id = anchor.id
                    let name = anchor.referenceObject.name.lowercased().replacingOccurrences(of: "_", with: " ")
                    
                    let detectedObjectName = objectDetectionRealityViewModel.getDetectedObjectName(detectedObject: name)
                    
                    if(detectedObjectName == appState.recognizedText || detectionView){
                        switch anchorUpdate.event {
                        case .added:
                            
                            let visualization = ObjectAnchorVisualization(for: anchor)
                            let entity = visualization.entity
                            entity.name = detectedObjectName
                            
                            if detectionView {
                                objectDetectionRealityViewModel.observeTouchedObject(for: entity) { name in
                                    viewModel.speak(text: "FOUNDUNKNOWNOBJECT".localizedWithArgs(name))
                                }
                            }
                            
                            if trackingView {
                                objectDetectionRealityViewModel.playSpatialSound(for: visualization.entity)
                            }
                            
                            self.objectVisualizations[id] = visualization
                            root.addChild(visualization.entity)
                            
                        case .updated:
                            self.objectVisualizations[id]?.update(with: anchor)
                        case .removed:
                            self.objectVisualizations[id]?.entity.removeFromParent()
                            self.objectVisualizations.removeValue(forKey: id)
                            
                        }
                    }
                }
            }
        }
        .onAppear() {
            appState.isImmersiveSpaceOpened = true
            if appState.realityView == "UnknownObjectDetection" {
                Task {
                    HandTrackingSystem.configure(with: appState)
                }
            }
        }
        .onDisappear() {
            if appState.realityView == "UnknownObjectDetection" {
                HandTrackingSystem.detectedObjects.removeAll()
            } else {
                for (_, visualization) in objectVisualizations {
                    root.removeChild(visualization.entity)
                }
                objectVisualizations.removeAll()
            }
            appState.didLeaveImmersiveSpace()
        }
    }
}
