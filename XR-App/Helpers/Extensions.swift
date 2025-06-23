//
//  Extensions.swift
//  XR-App
//
//  Created by Lisa Salzer on 23.06.25.
//

import Foundation
import SwiftUI


public extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localizedWithArgs(_ args: CVarArg...) -> String {
        String(format: self.localized, arguments: args)
    }
}

extension Comparable {
    /// Gibt den Wert zurück, begrenzt auf den angegebenen Wertebereich.
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}


