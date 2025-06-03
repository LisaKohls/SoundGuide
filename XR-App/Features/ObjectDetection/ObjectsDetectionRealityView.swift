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
                    print("determined object: \(detectedObjectName), recognized Text:\(appState.recognizedText) ")
                    if(appState.recognizedText.contains(detectedObjectName) || detectionView){
                        //searched for object has been found by Apple Vision Pro
                        switch anchorUpdate.event {
                        case .added:
                            print("Object has been found by Apple Vision pro: \(detectedObjectName)--- At: \(Date())", to: &logger)
                            print("Object has been found by Apple Vision pro: \(detectedObjectName)")
                           
                            let visualization = ObjectAnchorVisualization(for: anchor)
                            let entity = visualization.entity
                            entity.name = detectedObjectName
                            
                            if detectionView {
                                viewModel.observeTouchedObject(for: entity) { name in
                                    print("\(name) has been touched by user at: \(Date()) ----- Current view: \(appState.realityView)", to: &logger)
                                    print("\(name) has been touched by user ")
                                    SpeechHelper.shared.speak(text: "FOUNDUNKNOWNOBJECT".localizedWithArgs(name))
                                }
                            }
                            
                            if trackingView {
                                //Add outlines to detected object
                                self.objectVisualizations[id] = visualization
                                root.addChild(visualization.entity)
                                
                                //Add Spatial sound to the Object
                                let pos = anchor.originFromAnchorTransform.translation
                                viewModel.playSound(for: id, entity: visualization.entity, at: pos)
                                
                                //if object has been found by user, stop sound, play feedback
                                viewModel.observeTouchedObject(for: visualization.entity) { name in
                                    print("\(name) has been found by user at: \(Date()) ------- Current view: \(appState.realityView)", to: &logger)
                                    print("\(name) has been found by user")
                                   
                                    viewModel.stopSound(for: id)
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
                        // case .updated:
                            // self.objectVisualizations[id]?.update(with: anchor)
                            // let pos = anchor.originFromAnchorTransform.translation
                            // viewModel.updateSound(for: id, at: pos)
                            
                        case .updated:
                            self.objectVisualizations[id]?.update(with: anchor)
                            let objectPosition = anchor.originFromAnchorTransform.translation
                            viewModel.updateSound(for: id, at: objectPosition)

                                print("📦 Object position: x: \(objectPosition.x), y: \(objectPosition.y), z: \(objectPosition.z)")
                        
                            
                        case .removed:
                            self.objectVisualizations[id]?.entity.removeFromParent()
                            self.objectVisualizations.removeValue(forKey: id)
                            viewModel.stopSound(for: id)
                        }
                    }
                }
            }
        }
        .onAppear() {
            appState.isImmersiveSpaceOpened = true
            print("-------\(appState.realityView)---------- opened at: \(Date())", to: &logger)
            print("-------\(appState.realityView)---------- opened")
            Task {
                HandTrackingSystem.configure(with: appState)
            }
            
            SpeechHelper.shared.speak(text: "START_STOP_TRACKING_BTN".localizedWithArgs("STOP_BTN".localized,"STOP".localized))
        }
        .onDisappear() {
            print("View \(appState.realityView) disappeared at: \(Date())",to: &logger)
            print("View \(appState.realityView) disappeared")
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
