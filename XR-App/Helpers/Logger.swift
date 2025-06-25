//
//  Logger.swift
//  XR-App
//
//  Created by Lisa Kohls on 08.05.25.
//

/*
 Abstract:
 This file is for debugging and evaluation purposes only
 */

import Foundation

struct Log: TextOutputStream {
    
    func write(_ string: String) {
        let fm = FileManager.default
        let log = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("log.txt")
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] \(string)\n"
        
        if let handle = try? FileHandle(forWritingTo: log) {
            handle.seekToEndOfFile()
            handle.write(string.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? logEntry.data(using: .utf8)?.write(to: log)
        }
    }
}

var logger = Log()
