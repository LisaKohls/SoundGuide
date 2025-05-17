//
//  ReferenceObjectLoader.swift
//  XR-App
//
//  Created by Lisa Kohls on 22.03.25.

/*
 Abstract:
 The class that loads all available reference objects, max of 10 objects possible.
 */

import ARKit
import RealityKit

@MainActor
@Observable
final class ReferenceObjectLoader {
    
    private(set) var referenceObjects = [ReferenceObject]()
    private(set) var usdzsPerReferenceObjectID = [UUID: Entity]()
    private(set) var progress: Float = 1.0
    
    var enabledReferenceObjects = [ReferenceObject]()
    var enabledReferenceObjectsCount: Int { enabledReferenceObjects.count }
    var didFinishLoading: Bool { progress >= 1.0 }
    
    private var didStartLoading = false
    private var fileCount: Int = 0
    private var filesLoaded: Int = 0
    
    func setUSDZModel(_ model: Entity, for id: UUID) {
        usdzsPerReferenceObjectID[id] = model
    }
    
    private func updateProgress() {
        if fileCount == 0 {
            progress = 1.0
        } else if filesLoaded == fileCount {
            progress = 1.0
        } else {
            progress = Float(filesLoaded) / Float(fileCount)
        }
    }
    
    private func finishedOneFile() {
        filesLoaded += 1
        updateProgress()
    }
    
    func loadBuiltInReferenceObjects() async {
        guard !didStartLoading else { return }
        didStartLoading.toggle()
        
        var referenceObjectFiles: [String] = []
        if let resourcesPath = Bundle.main.resourcePath {
            try? referenceObjectFiles = FileManager.default.contentsOfDirectory(atPath: resourcesPath).filter { $0.hasSuffix(".referenceobject") }
        }
        
        fileCount = referenceObjectFiles.count
        updateProgress()
        
        await withTaskGroup(of: Void.self) { group in
            for file in referenceObjectFiles {
                let objectURL = Bundle.main.bundleURL.appending(path: file)
                group.addTask {
                    await self.loadReferenceObject(objectURL)
                    await self.finishedOneFile()
                }
            }
        }
    }
    
    private func loadReferenceObject(_ url: URL) async {
        var referenceObject: ReferenceObject
        do {
            try await referenceObject = ReferenceObject(from: url)
        } catch {
            fatalError("Error loading reference Objects: \(error)")
        }
        
        referenceObjects.append(referenceObject)
        
        enabledReferenceObjects.append(referenceObject)
        
        if let usdzPath = referenceObject.usdzFile {
            var entity: Entity? = nil
            
            do {
                try await entity = Entity(contentsOf: usdzPath)
            } catch {
                print("Failed to load model \(usdzPath.absoluteString)")
            }
            
            usdzsPerReferenceObjectID[referenceObject.id] = entity
        }
    }
    
    func addReferenceObject(_ url: URL) async {
        fileCount += 1
        await self.loadReferenceObject(url)
        self.finishedOneFile()
    }
    
    func removeObject(_ referenceObject: ReferenceObject) {
        referenceObjects.removeAll { $0.id == referenceObject.id }
        enabledReferenceObjects.removeAll { $0.id == referenceObject.id }
        fileCount = referenceObjects.count
    }
    
    func removeObjects(atOffsets offsets: IndexSet) {
        referenceObjects.remove(atOffsets: offsets)
        enabledReferenceObjects.removeAll(where: { object in
            !referenceObjects.contains(where: { $0.id == object.id })
        })
        fileCount = referenceObjects.count
    }
}
