//
//  ObjectsDetectionRealityView.swift
//  XR-App
//
//  Created by Lisa Kohls on 07.05.25.
//  Reference: https://github.com/dilmerv/VisionOSObjectTrackingDemo

/*
 Abstract:
 The applications immersive view, which enables the Object Tracking.
 */

import RealityKit
import ARKit
import SwiftUI
import RealityKitContent

@MainActor
struct ObjectsDetectionRealityView: View {
    
    @Bindable var appState: AppState
    var root = Entity()
    
    @StateObject var viewModel = ObjectsDetectionRealityViewModel()
    @State private var objectVisualizations: [UUID: ObjectAnchorVisualization] = [:]
    
    var body: some View {
        RealityView { content in
            content.add(root)
            viewModel.makeHandEntities(in: content)
            
            let currentContent = content
            
            Task {
                if appState.realityView == "ObjectIdentificationView" {
                    await handleObjectIdentificationView(content: currentContent)
                } else if appState.realityView == "SearchForObjectsView" {
                    await handleSearchForObjectsView(content: currentContent)
                }
            }
        }
        .id(appState.realityView) 
        .onAppear {
            appState.isImmersiveSpaceOpened = true
            Task {
                HandTrackingSystem.configure(with: appState)
            }
            
        }
        .onDisappear {
            Task {
                HandTrackingSystem.detectedObjects.removeAll()
                for (_, visualization) in objectVisualizations {
                    root.removeChild(visualization.entity)
                }
                objectVisualizations.removeAll()
                appState.didLeaveImmersiveSpace()
            }
        }
    }
    
    // MARK: - Objdect Identification View Handling
    
    private func handleObjectIdentificationView(content: RealityViewContent) async {
        SpeechHelper.shared.speak(text: "VIEWLOADED_UNKNOWNOBJECTS".localized)
        guard let objectTracking = await appState.startTracking() else { return }
        
        for await anchorUpdate in objectTracking.anchorUpdates {
            let anchor = anchorUpdate.anchor
            let id = anchor.id
            let name = anchor.referenceObject.name.lowercased().replacingOccurrences(of: "_", with: " ")
            let detectedName = viewModel.getDetectedObjectName(detectedObject: name)
            
            switch anchorUpdate.event {
            case .added:
                let visualization = ObjectAnchorVisualization(for: anchor)
                let entity = visualization.entity
                entity.name = detectedName
                
                viewModel.observeTouchedObject(for: entity) { name in
                    SpeechHelper.shared.speak(text: "FOUNDUNKNOWNOBJECT".localizedWithArgs(name))
                
                }
                
            case .updated:
                objectVisualizations[id]?.update(with: anchor)
            case .removed:
                objectVisualizations[id]?.entity.removeFromParent()
                objectVisualizations.removeValue(forKey: id)
            }
        }
    }
    
    // MARK: - Object Search View Handling
    
    private func handleSearchForObjectsView(content: RealityViewContent) async {
        SpeechHelper.shared.speak(text: "VIEWLOADED_SEARCHOBJECTS".localized)
        guard let objectTracking = await appState.startTracking() else { return }
        
        for await anchorUpdate in objectTracking.anchorUpdates {
            let anchor = anchorUpdate.anchor
            let id = anchor.id
            let name = anchor.referenceObject.name.lowercased().replacingOccurrences(of: "_", with: " ")
            let detectedName = viewModel.getDetectedObjectName(detectedObject: name)
            
            if appState.recognizedText.contains(detectedName) {
                switch anchorUpdate.event {
                case .added:
                    let model = appState.referenceObjectLoader.usdzsPerReferenceObjectID[anchor.referenceObject.id]
                    let visualization = ObjectAnchorVisualization(for: anchor, withModel: model)
                    let entity = visualization.entity
                    entity.name = detectedName
                    
                    objectVisualizations[id] = visualization
                    root.addChild(entity)
                    SpatialAudioManager.shared.playSound(for: entity)
                    
                    viewModel.observeTouchedObject(for: entity) { name in
                        SpeechHelper.shared.speak(text: "FOUNDUNKNOWNOBJECT".localizedWithArgs(name))
                        
                        Task {
                            HandTrackingSystem.detectedObjects.removeAll()
                            for (_, vis) in objectVisualizations {
                                root.removeChild(vis.entity)
                            }
                            objectVisualizations.removeAll()
                            appState.didFinishObjectDetection = true
                        }
                    }
                case .updated:
                    objectVisualizations[id]?.update(with: anchor)
                case .removed:
                    objectVisualizations[id]?.entity.removeFromParent()
                    objectVisualizations.removeValue(forKey: id)
                }
            }
        }
    }
}
