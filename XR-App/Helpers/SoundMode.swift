//
//  SoundMode.swift
//  XR-App
//
//  Created by Lisa Salzer on 22.06.25.
//

enum SoundMode: String, CaseIterable, Identifiable {
    case staticFile1
    case staticFile2
    case staticFile3
    case staticFile4
    case staticFile5

    var id: String { self.rawValue }

    var fileName: String {
        switch self {
        case .staticFile1: return "E10.wav"
        case .staticFile2: return "E1.wav"
        case .staticFile3: return "S6.mp3"
        case .staticFile4: return "S8.wav"
        case .staticFile5: return "spatial-sound.wav"
        }
    }
    
    var gain: Double {
           switch self {
           case .staticFile1: return 7
           case .staticFile2: return 0
           case .staticFile3: return 0
           case .staticFile4: return 15
           case .staticFile5: return -5
           }
       }

    var label: String {
        switch self {
        case .staticFile1: return "Ton 1"
        case .staticFile2: return "Ton 2"
        case .staticFile3: return "Ton 3"
        case .staticFile4: return "Ton 4"
        case .staticFile5: return "Ton 5"
        }
    }
}


