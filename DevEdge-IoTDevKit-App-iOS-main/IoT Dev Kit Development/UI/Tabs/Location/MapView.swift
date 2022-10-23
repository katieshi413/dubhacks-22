//
//  MapView.swift
//  Dev Kit
//
//  Created by Blake Bollinger on 6/16/21.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    
    /// The center of the map view. Our coordinator keeps this updated to match the wrapped map view's center coordinate as the user pans around.
    /// The LocationScreen can set it to tell us to center the map view on a specific coordinate.
    /// Changes trigger a call to `updateUIView(_ view: MKMapView, context: Context)`.
    @Binding var mapCenterCoordinate: CLLocationCoordinate2D

    /// The current location of the board, as provided and kept updated by the LocationScreen.
    /// Changes trigger a call to `updateUIView(_ view: MKMapView, context: Context)`.
    var boardLocationCoordinate: CLLocationCoordinate2D?

    /// The annotation that should be showes on the map, as provided and kept updated by the LocationScreen.
    /// Changes trigger a call to `updateUIView(_ view: MKMapView, context: Context)`.
    var annotation: MKPointAnnotation?
    
    /// A button the user can tap to center the map on a connected board's location.
    private let mapCenteringButton = UIButton(type: .system)

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = false
        
        // Add a button to let the user center the map on the board's location.
        addMapCenteringButtonTo(view: mapView, context: context)
        
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        // This method is triggered by changes in the SwiftUI parent of this MapView.
        // Our job is to update the UIKit view to reflect the new state.

        let centerCoordinateChanged = view.centerCoordinate != mapCenterCoordinate
        if boardLocationCoordinate == nil && centerCoordinateChanged {
            // The map was initialized while there was no known location for a board. Either because one wasn't
            // connected, or because we haven't yet received the location from the connected board.
            // In this case we set a zoom level that shows a large section of the map.
            let region = MKCoordinateRegion(center: mapCenterCoordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 60))
            view.setRegion(region, animated: false)
            
        } else if let boardLocationCoordinate = boardLocationCoordinate {
            if context.coordinator.boardLocationCoordinate == nil || centerCoordinateChanged {
                // This means that either:
                // 1. The map was initialized while a board was connected and had a known location.
                // 2. An initial location for a newly connected board was determined.
                // 3. The SwiftUI world triggered a re-centering while a board was connected and had a known location.
                // In either case we zoom into the board's location.
                let newCenterCoordinate = CLLocationCoordinate2D(latitude: boardLocationCoordinate.latitude,
                                                                 longitude: boardLocationCoordinate.longitude)
                let region = MKCoordinateRegion(center: newCenterCoordinate,
                                                latitudinalMeters: 20000, longitudinalMeters: 20000)
                view.setRegion(region, animated: true)
                
            }
        }

        // Update the coordinator's locationBoard property to keep it in sync with the SwiftUI world.
        context.coordinator.boardLocationCoordinate = boardLocationCoordinate
        
        // To avoid the map annotation flickering we only replace it if it has actually changed.
        if !annotationsMatch(annotation, view.annotations.first as? MKPointAnnotation) {
            view.removeAnnotations(view.annotations)
            if let annotation = annotation {
                view.addAnnotation(annotation)
            }
        }
        
        // Set the map centering button's state.
        // NOTE: It's important to poke at the coordinator's properties instead of self's properties.
        context.coordinator.parent.mapCenteringButton.isHidden = locationIsVisibleOn(mapView: view, location: context.coordinator.boardLocationCoordinate)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var boardLocationCoordinate: CLLocationCoordinate2D? = nil

        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            // Tell the SwifUI world about the new center of the map via the binding variable.
            parent.mapCenterCoordinate = mapView.centerCoordinate
        }
        
        @objc func centerMapOnBoardLocation(_ sender: Any) {
            guard let newCenterCoordinate = boardLocationCoordinate else { return }
            // Tell the SwifUI world that we want to center the map on a coordinate.
            parent.mapCenterCoordinate = newCenterCoordinate
        }
    }
    
    // MARK: - Private methods
    /// Adds a UIButton as a subview onto the view, to allow the user to re-center the map to the connected board's location.
    private func addMapCenteringButtonTo(view: UIView, context: MapView.Context) {
        let button = self.mapCenteringButton
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 38, weight: .light, scale: .medium)
        button.setImage(UIImage(systemName: "location.circle", withConfiguration: largeConfig), for: .normal)
        button.addTarget(context.coordinator, action: #selector(Coordinator.centerMapOnBoardLocation(_ :)), for: .touchUpInside)
        button.backgroundColor = UIColor.systemBackground
        button.sizeToFit()
        button.layer.cornerRadius = min(button.bounds.size.width, button.bounds.size.height) / 2.0
        view.addSubview(button)
        
        // Layout using Autolayout constraints.
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            button.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5),
        ])
    }
    
    /// Evaluates whether the board location is visible on the map.
    private func locationIsVisibleOn(mapView: MKMapView, location: CLLocationCoordinate2D?) -> Bool {
        guard let locationCoordinate = location else { return true }

        // The board's distance from the center of the map, in each direction.
        let latitudeDifference = abs(locationCoordinate.latitude - mapView.centerCoordinate.latitude)
        let longitudeDifference = abs(locationCoordinate.longitude - mapView.centerCoordinate.longitude)
        
        // The distance from the center of the map that is visible on screen, in each direction.
        let visibleMapSpanFromCenterLatitude = mapView.region.span.latitudeDelta / 2.0
        let visibleMapSpanFromCenterLongitude = mapView.region.span.longitudeDelta / 2.0
        
        // Return whether the board falls inside the visible region of the map or not.
        return latitudeDifference < visibleMapSpanFromCenterLatitude && longitudeDifference < visibleMapSpanFromCenterLongitude
    }
    
    /// Evaluates whether the provided annotations contain the same information.
    private func annotationsMatch(_ lhs: MKPointAnnotation?, _ rhs: MKPointAnnotation? ) -> Bool {
        if lhs == nil && rhs == nil { return true }                 // Both are nil, they match.
        guard let lhs = lhs, let rhs = rhs else { return false }    // Only one is nil, they do not match.

        // Check if any of the title, subtitle or coordinate fields differ.
        let matchingState = lhs.title == rhs.title && lhs.subtitle == rhs.subtitle && lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude
        return matchingState
    }
}

// MARK: Preview
extension MKPointAnnotation {
    static var previewAnnotation: MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.title = "Space Needle"
        annotation.subtitle = "Observation Deck & Tower"
        annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(47.62), longitude: CLLocationDegrees(-122.35))
        return annotation
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(mapCenterCoordinate: .constant(MKPointAnnotation.previewAnnotation.coordinate), annotation: MKPointAnnotation.previewAnnotation)
    }
}
