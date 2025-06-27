//
//  Extensions.swift
//  XR-App
//
//  Created by Lisa Salzer on 23.06.25.
//
//  References:
//  [10] https://developer.apple.com/documentation/foundation/nslocalizedstring
//  [11] https://github.com/swiftlang/swift-evolution/blob/main/proposals/0177-add-clamped-to-method.md
//

/*
 Abstract:
 Adds localization support to String.
 */

import Foundation
import SwiftUI

// [10]
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

// [11]
extension Comparable {
    /// Gibt den Wert zurück, begrenzt auf den angegebenen Wertebereich.
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}


