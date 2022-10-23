//
//  LocationBox.swift
//  IoT Dev Kit Development
//
//  Created by Blake Bollinger on 11/18/21.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI
import MapKit

struct LocationBox: View {
    
    var location: BoardLocation.LocationState = .undetermined
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }
    
    var body: some View {
        
        ZStack {
        
            RoundedRectangle(cornerRadius: 6)
                .fill(Material.regularMaterial)
            
            VStack {
                switch location {
                case .located(let latitude, let longitude, let elevation, let timestamp):
                    HStack{
                        Text("Latitude:")
                        Spacer()
                        Text("\(latitude, specifier: "%.5f°")")
                            .monospacedDigit()
                    }
                    Spacer()
                    HStack{
                        Text("Longitude:")
                        Spacer()
                        Text("\(longitude, specifier: "%.5f°")")
                            .monospacedDigit()
                    }
                    
                    if let elevation = elevation {
                        Spacer()
                        HStack{
                            Text("Elevation:")
                            Spacer()
                            Text("\(elevation, specifier: "%.2f m")")
                                .monospacedDigit()
                        }
                    }
                    
                    Spacer()
                    HStack{
                        Text("Timestamp:")
                        Spacer()
                        Text("\( dateFormatter.string(from: timestamp) )")
                            .monospacedDigit()
                    }
                case .undetermined:
                    Text("Location unavailable")
                }
            }
            .padding(16)
            .foregroundColor(.tmoGray70)
            .dynamicTypeSize(...(.accessibility1))
        }
        .shadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.15), radius: 6, x: 0, y: 0)
        
    }
    
}

struct LocationBox_Previews: PreviewProvider {
    static var previews: some View {
        LocationBox()
    }
}
