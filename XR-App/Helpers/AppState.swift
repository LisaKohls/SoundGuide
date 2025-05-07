//
//  AppState.swift
//  XR-App
//
//  Created by Lisa Kohls on 22.03.25.

/*
 Abstract:
 The app's overall state.
 */

import ARKit
import RealityKit
import RealityKitContent;
import RealityFoundation

@MainActor
@Observable
class AppState {
    
    var isImmersiveSpaceOpened = false
    
    let referenceObjectLoader = ReferenceObjectLoader()
    
    func didLeaveImmersiveSpace() {
        // Stop the provider; the provider that just ran in the
        // immersive space is now in a paused state and isn't needed
        // anymore. When a person reenters the immersive space,
        // run a new provider.
        arkitSession.stop()
        isImmersiveSpaceOpened = false
    }
    
    // MARK: - ARKit state
    
    private var arkitSession = ARKitSession()
    
    private var objectTracking: ObjectTrackingProvider? = nil
    
    private var handTracking: HandTrackingProvider? = nil
    
    var objectTrackingStartedRunning = false
    
    var providersStoppedWithError = false
    
    var worldSensingAuthorizationStatus = ARKitSession.AuthorizationStatus.notDetermined
    
    var recognizedText: String = ""
    
    var realityView: String = ""
    
    func startTracking() async -> ObjectTrackingProvider? {
        let referenceObjects = referenceObjectLoader.enabledReferenceObjects
        
        guard !referenceObjects.isEmpty else {
            fatalError("No reference objects to start tracking")
        }
        
        let objectTracking = ObjectTrackingProvider(referenceObjects: referenceObjects)
        do {
            try await arkitSession.run([objectTracking])
        } catch {
            print("Error starting object tracking: \(error)" )
            return nil
        }
        self.objectTracking = objectTracking
        return objectTracking
    }
    
    func startHandTracking() async -> HandTrackingProvider? {
        let handTracking = HandTrackingProvider()
        do {
            try await arkitSession.run([handTracking])
        } catch {
            print("Error starting hand tracking: \(error)" )
            return nil
        }
        self.handTracking = handTracking
        return handTracking
    }
    
    var allRequiredAuthorizationsAreGranted: Bool {
        worldSensingAuthorizationStatus == .allowed
    }
    
    var allRequiredProvidersAreSupported: Bool {
        ObjectTrackingProvider.isSupported
    }
    
    var canEnterImmersiveSpace: Bool {
        allRequiredAuthorizationsAreGranted && allRequiredProvidersAreSupported
    }
    
    func requestWorldSensingAuthorization() async {
        let authorizationResult = await arkitSession.requestAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing]!
    }
    
    func queryWorldSensingAuthorization() async {
        let authorizationResult = await arkitSession.queryAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = authorizationResult[.worldSensing]!
    }
    
    func monitorSessionEvents() async {
        for await event in arkitSession.events {
            switch event {
            case .dataProviderStateChanged(let providers, let newState, let error):
                switch newState {
                case .initialized:
                    break
                case .running:
                    guard objectTrackingStartedRunning == false, let objectTracking else { continue }
                    for provider in providers where provider === objectTracking {
                        objectTrackingStartedRunning = true
                        break
                    }
                case .paused:
                    break
                case .stopped:
                    guard objectTrackingStartedRunning == true, let objectTracking else { continue }
                    for provider in providers where provider === objectTracking {
                        objectTrackingStartedRunning = false
                        break
                    }
                    if let error {
                        print("An error occurred: \(error)")
                        providersStoppedWithError = true
                    }
                @unknown default:
                    break
                }
            case .authorizationChanged(let type, let status):
                print("Authorization type \(type) changed to \(status)")
                if type == .worldSensing {
                    worldSensingAuthorizationStatus = status
                }
            default:
                print("An unknown event occurred \(event)")
            }
        }
    }
}
