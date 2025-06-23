//
//  SpeechSettingsView.swift
//  XR-App
//
//  Created by Lisa Salzer on 20.06.25.
//

import SwiftUI

struct SettingsView: View {
    @Binding var speechRate: Float
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSound: SoundMode = {
        if let stored = UserDefaults.standard.string(forKey: "soundMode"),
           let mode = SoundMode(rawValue: stored) {
            return mode
        }
        return .staticFile1
    }()
    
    @State private var reverbLevel: Double = UserDefaults.standard.double(forKey: "reverbLevel").clamped(to: 0...10)
    @State private var rolloffFactor: Double = UserDefaults.standard.double(forKey: "rolloffFactor").clamped(to: 0.1...10)


    private var speechLabel: String {
        switch speechRate {
        case ..<0.35: return "Langsam"
        case 0.35..<0.7: return "Normal"
        default: return "Schnell"
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Sprachgeschwindigkeit")
                .font(.title2)
                .bold()

            Slider(value: $speechRate, in: 0.2...0.9, step: 0.05, onEditingChanged: { isEditing in
                if !isEditing {
                    SpeechHelper.shared.speak(text: "Dies ist ein Geschwindigkeitstest", rate: speechRate)
                }
            })
            .padding(.horizontal)
            .accessibilityLabel("Sprachgeschwindigkeit Slider")
            .accessibilityValue(speechLabel)
            

            Text("Aktuell: \(speechLabel) (\(String(format: "%.2f", speechRate)))")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Aktuelle Sprachgeschwindigkeit: \(speechLabel)")
            
            Divider()
            
            // Soundauswahl
                        Text("Hinweiston auswählen")
                            .font(.title2)
                            .bold()
                            .accessibilityAddTraits(.isHeader)


                        Picker("Ton", selection: $selectedSound) {
                            ForEach(SoundMode.allCases) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.inline)
                        .onChange(of: selectedSound) { newValue in
                            SoundPreviewHelper.shared.playSound(named: newValue.fileName)
                        }
                        .accessibilityLabel("Hinweiston auswählen")
            
                        Divider()

                        // Audio Anpassungen
                        Text("Audio Anpassungen")
                            .font(.title2)
                            .bold()
                            .accessibilityAddTraits(.isHeader)

                        VStack(alignment: .leading) {
                            Text("Hall (Nachhallstärke): \(String(format: "%.1f", reverbLevel))")
                            Slider(value: $reverbLevel, in: 0...10, step: 0.1, onEditingChanged: { editing in
                                if !editing {
                                    SpeechHelper.shared.speak(text: "Nachhall auf \(Int(reverbLevel * 10)) Prozent")
                                }
                            })
                            .accessibilityLabel("Nachhallstärke")
                            .accessibilityValue("\(Int(reverbLevel * 10)) Prozent")
                        }

                        VStack(alignment: .leading) {
                            Text("Lautstärkeabnahme bei Entfernung: \(String(format: "%.1f", rolloffFactor))")
                            Slider(value: $rolloffFactor, in: 0.1...10, step: 0.1, onEditingChanged: { editing in
                                if !editing {
                                    SpeechHelper.shared.speak(text: "Lautstärkeabnahme auf \(String(format: "%.1f", rolloffFactor))")
                                }
                            })
                            .accessibilityLabel("Lautstärkeabnahme bei Entfernung")
                            .accessibilityValue("\(String(format: "%.1f", rolloffFactor))")
                        }

            

                        Spacer()

                        // Speichern
                        Button("Speichern & Zurück") {
                            UserDefaults.standard.set(speechRate, forKey: "speechRate")
                            UserDefaults.standard.set(selectedSound.rawValue, forKey: "soundMode")
                            UserDefaults.standard.set(reverbLevel, forKey: "reverbLevel")
                            UserDefaults.standard.set(rolloffFactor, forKey: "rolloffFactor")
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Einstellungen speichern und zurückgehen")
                    }
                    .padding()
    }
}



