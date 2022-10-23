//
//  Data.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 3/7/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import Foundation

extension Data {
    /// Parses the `Data` instance as a String, disregarding any bytes after the Null termination character.
    ///
    /// - parameter encoding: The `String.Encoding` to parsing the `String`. Defaults to UTF-8.
    /// - returns: A `String`, or `nil` if parsing fails.
    func parseAsNullTerminatedString(encoding: String.Encoding = .utf8) -> String? {
        var data = self
        
        let nullIndex = data.firstIndex(of: 0) // Find the Null termination character.
        
        // Remove all bytes after the Null termination character.
        if let nullIndex = nullIndex {
            data.removeLast(data.count - nullIndex)
        }

        guard let parsedString = String(bytes: data, encoding: encoding) else { return nil }
        return parsedString
    }
}
