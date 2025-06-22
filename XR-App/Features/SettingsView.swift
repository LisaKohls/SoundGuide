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

                        Picker("Ton", selection: $selectedSound) {
                            ForEach(SoundMode.allCases) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.inline)
                        .onChange(of: selectedSound) { newValue in
                            SoundPreviewHelper.shared.playSound(named: newValue.fileName)
                        }

                        Spacer()

                        // Speichern
                        Button("Speichern & Zurück") {
                            UserDefaults.standard.set(speechRate, forKey: "speechRate")
                            UserDefaults.standard.set(selectedSound.rawValue, forKey: "soundMode")
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Einstellungen speichern und zurückgehen")
                    }
                    .padding()
    }
}



