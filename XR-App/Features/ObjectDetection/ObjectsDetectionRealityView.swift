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
    
    @StateObject var viewModel = ObjectsDetectionRealityViewModel()
    @State private var objectVisualizations: [UUID: ObjectAnchorVisualization] = [:]
    
    
    var body: some View {
        RealityView { content in
            content.add(root)
            
            let detectionView = appState.realityView == "UNKNOWNOBJECTS_BTN".localized
            let trackingView = appState.realityView == "START_BTN".localized
            
            viewModel.makeHandEntities(in: content)
       
            Task {
                let objectTracking = await appState.startTracking()
                guard let objectTracking else {
                    return
                }
                
                for await anchorUpdate in objectTracking.anchorUpdates {
                    let anchor = anchorUpdate.anchor
                    let id = anchor.id
                    let name = anchor.referenceObject.name.lowercased().replacingOccurrences(of: "_", with: " ")
                    
                    let detectedObjectName = viewModel.getDetectedObjectName(detectedObject: name)
                    
                    if(detectedObjectName == appState.recognizedText || detectionView){
                        //searched for object has been found by Apple Vision Pro
                        switch anchorUpdate.event {
                        case .added:
                            print("Object has been found by Apple Vision pro: \(detectedObjectName)--- At: \(Date())", to: &logger)
                           
                            let visualization = ObjectAnchorVisualization(for: anchor)
                            let entity = visualization.entity
                            entity.name = detectedObjectName
                            
                            if detectionView {
                                viewModel.observeTouchedObject(for: entity) { name in
                                    print("\(name) has been touched by user at: \(Date()) ----- Current view: \(appState.realityView)", to: &logger)
                                   
                                    SpeechHelper.shared.speak(text: "FOUNDUNKNOWNOBJECT".localizedWithArgs(name))
                                }
                            }
                            
                            if trackingView {
                                //Add outlines to detected object
                                self.objectVisualizations[id] = visualization
                                root.addChild(visualization.entity)
                                
                                //Add Spatial sound to the Object
                                viewModel.playSpatialSound(for: visualization.entity, resourceName: "spatial-sound.wav")
                                
                                //if object has been found by user, stop sound, play feedback Ping
                                viewModel.observeTouchedObject(for: visualization.entity) { name in
                                    print("\(name) has been found by user at: \(Date()) ------- Current view: \(appState.realityView)", to: &logger)
                                   
                                    viewModel.stopSpatialSound()
                                    SpeechHelper.shared.speak(text: "FOUNDUNKNOWNOBJECT".localizedWithArgs(name))
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
            print("-------\(appState.realityView)---------- opened at: \(Date())", to: &logger)
            Task {
                HandTrackingSystem.configure(with: appState)
            }
        }
        .onDisappear() {
            print("View \(appState.realityView) disappeared at: \(Date())",to: &logger)
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
