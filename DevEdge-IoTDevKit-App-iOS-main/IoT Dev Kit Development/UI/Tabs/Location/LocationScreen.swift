//
//  LocationScreen.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 11/16/21.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI
import MapKit

/// A view to present the location coordinates of the connected Bluetooth board and show the location on a map.
struct LocationScreen: View {
    
    @ObservedObject private var boardLocation = Board.shared.boardLocation

    // This `centerCoordinate` is initialized to a coordinate here, but also gets updated when the MapView is scrolled around.
    // Center on USA midpoint if the board's location is unavailable: lat 39.8, long -98.8.
    @State private var mapViewCenterCoordinate: CLLocationCoordinate2D = Board.shared.boardLocation.state.coordinate() ?? CLLocationCoordinate2D(latitude:39.8, longitude: -98.8)

    var body: some View {
        NavigationView {
            VStack {
                MapView(mapCenterCoordinate: $mapViewCenterCoordinate, boardLocationCoordinate: boardLocation.state.coordinate(), annotation: boardAnnotation)
                    .edgesIgnoringSafeArea(.horizontal)
                    .overlay(alignment: .bottomLeading) {
                        LocationBox(location: boardLocation.state)
                            .padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 0))
                            .fixedSize()
                    }
                    .onChange(of: mapViewCenterCoordinate) { coordinate in
                        // The map view's center coordinate changed. We don't currently do anything with this information.
                    }
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(){
                ToolbarItemGroup(placement: .navigationBarLeading){
                    Button("Devices"){
                        AppController.shared.shouldShowDeviceSelectionSheet = true
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private var boardAnnotation: MKPointAnnotation? {
        
        switch boardLocation.state {
        case .located(let latitude, let longitude, _, let timestamp):
            let annotation = MKPointAnnotation()
            annotation.title = Board.shared.boardName
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .medium
            
            annotation.subtitle = "Last located at \(dateFormatter.string(from:timestamp))"
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude),
                                                           longitude: CLLocationDegrees(longitude))
            
            return annotation
        case .undetermined:
            return nil
        }
    }
}


struct LocationScreen_Previews: PreviewProvider {
    static var previews: some View {
        LocationScreen()
            .previewDevice("iPod touch (7th generation)")
            .environment(\.sizeCategory, .large)
    }
}
