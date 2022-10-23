//
//  CLLocationCoordinate2D.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 5/18/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.longitude == rhs.longitude && lhs.latitude == rhs.latitude
    }
}
