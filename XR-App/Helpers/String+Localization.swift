//
//  String+Localization.swift
//  XR-App
//
//  Created by Lisa Kohls on 04.05.25.
//

/*
 Abstract:
 The string localization file for different languages within the app.
 */

import Foundation

public extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localizedWithArgs(_ args: CVarArg...) -> String {
        String(format: self.localized, arguments: args)
    }
}
