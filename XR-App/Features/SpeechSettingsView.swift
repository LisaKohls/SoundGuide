//
//  SpeechSettingsView.swift
//  XR-App
//
//  Created by Lisa Salzer on 20.06.25.
//

import SwiftUI

struct SpeechSettingsView: View {
    @Binding var speechRate: Float
    @Environment(\.dismiss) private var dismiss

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

            Slider(value: $speechRate, in: 0.2...0.9, step: 0.05)
                .padding(.horizontal)

            Text("Aktuell: \(speechLabel) (\(String(format: "%.2f", speechRate)))")
                .foregroundStyle(.secondary)

            Button("Testausgabe") {
                SpeechHelper.shared.speak(text: "Dies ist ein Geschwindigkeitstest", rate: speechRate)
            }
            .padding(.top)
            .buttonStyle(.bordered)

            Spacer()

            Button("Speichern & Zurück") {
                UserDefaults.standard.set(speechRate, forKey: "speechRate")
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}



