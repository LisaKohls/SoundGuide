//
//  ObjectTrackingRealityView.swift
//  XR-App
//
//  Created by Lisa Kohls on 22.03.25.

/*
Abstract:
The view shown inside the immersive space.
*/

import RealityKit
import ARKit
import SwiftUI

@MainActor
struct ObjectTrackingRealityView: View {
    
    @StateObject var speechRecognizer = SpeechRecognizer()
    
    var appState: AppState
    var root = Entity()
    
    @State private var objectVisualizations: [UUID: ObjectAnchorVisualization] = [:]

    var body: some View {
        RealityView { content in
            content.add(root)
            
            Task {
                let objectTracking = await appState.startTracking()
                guard let objectTracking else {
                    return
                }
                
                for await anchorUpdate in objectTracking.anchorUpdates {
                    let anchor = anchorUpdate.anchor
                    let id = anchor.id
                    
                    switch anchorUpdate.event {
                    case .added:
                        let model = appState.referenceObjectLoader.usdzsPerReferenceObjectID[anchor.referenceObject.id]
                        let visualization = ObjectAnchorVisualization(for: anchor, withModel: model)
                        
                        //add audio to object entity
                        let resource: AudioFileResource = try .load(named: "spatial-sound.wav", in: .main)
                        let controller = visualization.entity.prepareAudio(resource)
                        
                        
                        speechRecognizer.onResult = { recognizedText in
                            print("Erkannt: \(recognizedText)")
                            print("visualization.entity: \(visualization.entity)")
                        }
                        
                        speechRecognizer.startRecognition()
                        
                        //controller.play()
                        
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
        }
        .onDisappear() {
            for (_, visualization) in objectVisualizations {
                root.removeChild(visualization.entity)
            }
            objectVisualizations.removeAll()
            appState.didLeaveImmersiveSpace()
        }
    }
}
