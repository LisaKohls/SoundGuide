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
            
            objectDetectionRealityViewModel.makeHandEntities(in: content)
       
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
                        //searched for object has been found by Aplle Vision Pro
                        switch anchorUpdate.event {
                        case .added:
                            
                            let visualization = ObjectAnchorVisualization(for: anchor)
                            let entity = visualization.entity
                            entity.name = detectedObjectName
                            
                            self.objectVisualizations[id] = visualization
                            root.addChild(visualization.entity)
                            
                            if detectionView {
                                objectDetectionRealityViewModel.observeTouchedObject(for: entity) { name in
                                    viewModel.speak(text: "FOUNDUNKNOWNOBJECT".localizedWithArgs(name))
                                }
                            }
                            
                            if trackingView {
                                //Add Spatial sound to the Object
                                objectDetectionRealityViewModel.playSpatialSound(for: visualization.entity, resourceName: "spatial-sound.wav")
                                
                                //if object has been found by user, stop sound, play feedback Ping
                                objectDetectionRealityViewModel.observeTouchedObject(for: visualization.entity) { name in
                                    objectDetectionRealityViewModel.stopSpatialSound()
                                    viewModel.speak(text: "FOUNDUNKNOWNOBJECT".localizedWithArgs(name))
                                    Task {
                                        HandTrackingSystem.detectedObjects.removeAll()
                                         
                                         for (_, visualization) in objectVisualizations {
                                             root.removeChild(visualization.entity)
                                         }
                                         objectVisualizations.removeAll()
                                         appState.didFinishObjectDetection = true
                                     }
                                }
                                
                            }
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
            Task {
                HandTrackingSystem.configure(with: appState)
            }
        }
        .onDisappear() {
        print("disappeared objects detection")
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
}
