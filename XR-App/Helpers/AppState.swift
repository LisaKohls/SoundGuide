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
import RealityKitContent;
import RealityFoundation
@MainActor
class AppState: ObservableObject {
    
    @Published var isImmersiveSpaceOpened = false
    @Published var recognizedText: String = ""
    @Published var objectTrackingStartedRunning = false
    @Published var providersStoppedWithError = false
    @Published var worldSensingAuthorizationStatus = ARKitSession.AuthorizationStatus.notDetermined

    let referenceObjectLoader = ReferenceObjectLoader()
    private var objectTracking: ObjectTrackingProvider? = nil
    private var arkitSession = ARKitSession()

    var allRequiredAuthorizationsAreGranted: Bool {
        worldSensingAuthorizationStatus == .allowed
    }

    var allRequiredProvidersAreSupported: Bool {
        ObjectTrackingProvider.isSupported
    }

    var canEnterImmersiveSpace: Bool {
        allRequiredAuthorizationsAreGranted && allRequiredProvidersAreSupported
    }

    func startTracking() async -> ObjectTrackingProvider? {
        let referenceObjects = referenceObjectLoader.enabledReferenceObjects
        guard !referenceObjects.isEmpty else {
            fatalError("No reference objects to start tracking")
        }

        let objectTracking = ObjectTrackingProvider(referenceObjects: referenceObjects)
        do {
            try await arkitSession.run([objectTracking])
        } catch {
            print("Error: \(error)")
            return nil
        }
        self.objectTracking = objectTracking
        return objectTracking
    }

    func didLeaveImmersiveSpace() {
        arkitSession.stop()
        isImmersiveSpaceOpened = false
    }

    func requestWorldSensingAuthorization() async {
        let result = await arkitSession.requestAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = result[.worldSensing]!
    }

    func queryWorldSensingAuthorization() async {
        let result = await arkitSession.queryAuthorization(for: [.worldSensing])
        worldSensingAuthorizationStatus = result[.worldSensing]!
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
                if type == .worldSensing {
                    worldSensingAuthorizationStatus = status
                }
            default:
                print("Unknown event: \(event)")
            }
        }
    }

    // Falls du die Session woanders brauchst:
    var arSession: ARKitSession {
        arkitSession
    }
}
