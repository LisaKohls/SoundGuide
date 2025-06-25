//
//  SoundPreviewHelper.swift
//  XR-App
//
//  Created by Lisa Salzer on 22.06.25.
//
//  Reference: [1] https://developer.apple.com/documentation/avfaudio/avaudioplayer
//  Reference: [2] https://developer.apple.com/documentation/foundation/timer

/*
 Abstract:
 a helper class to play short sound previews in the settings
 */


import AVFoundation

// [1]
class SoundPreviewHelper {
    static let shared = SoundPreviewHelper()
    
    private var player: AVAudioPlayer?
    private var stopTimer: Timer?
    
    func playSound(named fileName: String) {
        stopTimer?.invalidate() // voriger Timer beenden
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("Sounddatei nicht gefunden: \(fileName)")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            
            // stop preview afer 3 seconds [2]
            stopTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                self?.player?.stop()
                self?.player = nil
            }
        } catch {
            print("Fehler beim Abspielen von \(fileName): \(error)")
        }
    }
}


