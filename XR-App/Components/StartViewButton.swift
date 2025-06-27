//
//  StartViewButton.swift
//  XR-App
//
//  Created by Lisa Salzer on 25.06.25.
//


import SwiftUI

struct OpenViewButton: View {
    let title: String
    let accessibilityLabel: String
    let action: () -> Void
    @Binding var isSpeaking: Bool

    var body: some View {
        Button(title) {
            action()
        }
        .accessibilityLabel(accessibilityLabel)
        .padding()
    }
}
