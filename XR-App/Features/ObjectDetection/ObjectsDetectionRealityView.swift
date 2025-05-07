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
    @State private var spokenObjectNames: Set<String> = []
    
    
    var body: some View {
        RealityView { content in
            content.add(root)
            
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
                    
                    
                    let detectedObjectName = switch name {
                    case "tasse": "MUG".localized
                    case "spices": "SPICES".localized
                    case "erdbeertee": "STRAWBERRYTEA".localized
                    case "zitronentee": "LEMONTEA".localized
                    default: name.lowercased()
                    }
                    
                    switch anchorUpdate.event {
                    case .added:
 
                        let visualization = ObjectAnchorVisualization(for: anchor)
                        let entity = visualization.entity
                        entity.name = detectedObjectName
                        HandTrackingSystem.detectedObjects.append(entity)
                        
                        HandTrackingSystem.onObjectTouched = { name in
                            guard !spokenObjectNames.contains(name) else { return }
                                
                            spokenObjectNames.insert(name)
                            viewModel.speak(text: "FOUNDUNKNOWNOBJECT".localizedWithArgs(name))
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
        .onAppear() {
            appState.isImmersiveSpaceOpened = true
            Task {
                HandTrackingSystem.configure(with: appState)
            }
        }
        .onDisappear() {
            appState.didLeaveImmersiveSpace()
            HandTrackingSystem.detectedObjects.removeAll()
        }
    }
}
