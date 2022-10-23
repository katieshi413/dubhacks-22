//
//  Array.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 5/25/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import Foundation

extension Array {

    /// Returns the element at the given `index` if it exists, or `nil` otherwise.
    /// Avoids `Fatal error: Index out of range` crashes, as it returns `nil` when called with an out of range index.
    func elementAt(index: Int?) -> Element? {
        if let index = index {
            if self.indices.contains(index) {
                return self[index]
            }
        }
        
        return nil
    }
}
