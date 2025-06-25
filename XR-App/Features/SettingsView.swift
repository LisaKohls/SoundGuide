//
//  SpeechSettingsView.swift
//  XR-App
//
//  Created by Lisa Salzer on 20.06.25.
//
//  References:
//  [1] https://developer.apple.com/documentation/swiftui/slider
//  [2] https://developer.apple.com/documentation/foundation/userdefaults
//  [3] https://developer.apple.com/documentation/swiftui/view-accessibility
//

/*
 Abstract:
 The applications settings view.
 */

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Load saved sound mode or use default
    @State private var selectedSound: SoundMode = {
        if let stored = UserDefaults.standard.string(forKey: "soundMode"),
           let mode = SoundMode(rawValue: stored) {
            return mode
        }
        return .staticFile1
    }()
    
    // Load and clamp stored values for customization sliders
    @State private var reverbLevel: Double = UserDefaults.standard.double(forKey: "reverbLevel").clamped(to: 0.5...5.0)
    @State private var rolloffFactor: Double = UserDefaults.standard.double(forKey: "rolloffFactor").clamped(to: 1.0...6.0)
    @State private var speechRate: Float = UserDefaults.standard.float(forKey: "speechRate").clamped(to: 0.1...0.8)
    
    // Return localized speech rate description depending on value
    private var speechLabel: String {
        switch speechRate {
        case ..<0.2:
            return "SPEECHRATE_LABEL_VERY_SLOW".localized
        case 0.2..<0.45:
            return "SPEECHRATE_LABEL_SLOW".localized
        case 0.45..<0.6:
            return "SPEECHRATE_LABEL_NORMAL".localized
        default:
            return "SPEECHRATE_LABEL_FAST".localized
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("SETTINGS_TITLE_SPEECHRATE".localized)
                .font(.title2)
                .bold()
            
            // [1] Slider to adjust speech rate (spoken when released)
            Slider(value: $speechRate, in: 0.1...0.8, step: 0.05, onEditingChanged: { isEditing in
                if !isEditing {
                    SpeechHelper.shared.speak(text: "SETTINGS_SPEECHRATE_TEST".localized, rate: speechRate)
                }
            })
            .padding(.horizontal)
            .accessibilityLabel("SETTINGS_TITLE_SPEECHRATE".localized) // [3] defines the label VoiceOver uses to describe the slider
            .accessibilityValue(speechLabel)
            
            // Show current speech rate value in text
            Text(String(format: "SETTINGS_SPEECHRATE_CURRENT".localized, speechLabel, speechRate))
                .foregroundStyle(.secondary)
                .accessibilityLabel(String(format: "SETTINGS_SPEECHRATE_CURRENT".localized, speechLabel, speechRate))
            
            Divider()
            
            // Select sound mode
            Text("SETTINGS_TITLE_SOUNDMODE".localized)
                .font(.title2)
                .bold()
                .accessibilityAddTraits(.isHeader)
            
            
            Picker("SETTINGS_TITLE_SOUNDMODE".localized, selection: $selectedSound) {
                ForEach(SoundMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.inline)
            .onChange(of: selectedSound) { _, newValue in
                SoundPreviewHelper.shared.playSound(named: newValue.fileName)
            }
            .accessibilityLabel("SETTINGS_TITLE_SOUNDMODE".localized)
            
            Divider()
            
            // Audio adjustments
            Text("SETTINGS_TITLE_AUDIO".localized)
                .font(.title2)
                .bold()
                .accessibilityAddTraits(.isHeader)
            
            // [1] Reverb level slider
            VStack(alignment: .leading) {
                Text(String(format: "SETTINGS_REVERB_LABEL".localized, reverbLevel))
                Slider(value: $reverbLevel, in: 0...5, step: 1.0, onEditingChanged: { editing in
                    if !editing {
                        SpeechHelper.shared.speak(text: String(format: "SETTINGS_REVERB_LABEL".localized, reverbLevel))
                    }
                })
                .accessibilityLabel("SETTINGS_REVERB_LABEL".localized)
                .accessibilityValue("\(Int(reverbLevel))")
            }
            
            // [1] Rolloff factor slider
            VStack(alignment: .leading) {
                Text(String(format: "SETTINGS_ROLLOFF_LABEL".localized, rolloffFactor))
                Slider(value: $rolloffFactor, in: 1.0...6.0, step: 1.0, onEditingChanged: { editing in
                    if !editing {
                        SpeechHelper.shared.speak(text: String(format: "SETTINGS_ROLLOFF_LABEL".localized, rolloffFactor))
                    }
                })
                .accessibilityLabel("SETTINGS_ROLLOFF_LABEL".localized)
                .accessibilityValue("\(Int(rolloffFactor))")
                
            }
            
            
            Spacer()
            
            // Save to user defaults [2]
            Button("SETTINGS_SAVE_BTN".localized) {
                UserDefaults.standard.set(speechRate, forKey: "speechRate")
                UserDefaults.standard.set(selectedSound.rawValue, forKey: "soundMode")
                UserDefaults.standard.set(reverbLevel, forKey: "reverbLevel")
                UserDefaults.standard.set(rolloffFactor, forKey: "rolloffFactor")
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("SETTINGS_SAVE_BTN_A11Y".localized)
        }
        .padding()
    }
}



