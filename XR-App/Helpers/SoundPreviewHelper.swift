//
//  SoundPreviewHelper.swift
//  XR-App
//
//  Created by Lisa Salzer on 22.06.25.
//

import AVFoundation

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

            // ⏱ Vorschau nach 3 Sekunden stoppen
            stopTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                self?.player?.stop()
                self?.player = nil
            }
        } catch {
            print("Fehler beim Abspielen von \(fileName): \(error)")
        }
    }
}


