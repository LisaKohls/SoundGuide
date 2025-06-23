//
//  Extensions.swift
//  XR-App
//
//  Created by Lisa Salzer on 23.06.25.
//

/*
 Abstract:
 Adds localization support to String.
 */

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

// MARK: Comparable

/*
 Abstract:
 Adds a method to clamp a Comparable value to a closed range.
 Ensures the value stays within the specified bounds.
 */


extension Comparable {
    /// Gibt den Wert zurück, begrenzt auf den angegebenen Wertebereich.
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}


