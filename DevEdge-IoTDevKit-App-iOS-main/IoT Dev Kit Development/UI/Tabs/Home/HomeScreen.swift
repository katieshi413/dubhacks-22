//
//  HomeScreen.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 11/16/21.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

/// The Home tab screen, which contains a number of cards to showing values from the connected Bluetooth device.
struct HomeScreen: View {
    @ObservedObject private var connectedBoard = Board.shared
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: Constants.cardSpacing) {
                        CardView(title: "Power", contentViews: powerViews)
                        CardView(title: "Connectivity", contentViews: connectivityViews)
                        NavigationLink(destination: EnvironmentScreen()){
                            CardView(title: "Environment", showChevron: true, contentViews: environmentViews)
                        }
                        NavigationLink(destination: IOScreen()){
                            CardView(title: "I/O", showChevron: true, contentViews: ioViews)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                }
                .background(Constants.backgroundColor)
            }
            .navigationTitle(connectedBoard.formattedBoardName)
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
    
    // MARK: The collections of views to present on each card on the Home screen.
    
    private var powerViews: [AnyView] {
        [
            AnyView ( CardIconValueView(icon: batteryImage(percentage: connectedBoard.batteryPercentage, runningOnBattery: connectedBoard.isOnBattery), value: connectedBoard.formattedBatteryLevel) ),
            AnyView( CardIconValueView(icon: acImage(runningOnBattery: connectedBoard.isOnBattery), value: connectedBoard.formattedAcStatus) )
        ]
    }
    private var connectivityViews: [AnyView] {
        [
            AnyView( CardIconValueView(icon: cellSignalImage(connected: connectedBoard.isCellNetworkConnected), value: connectedBoard.formattedCellSignalStrength) ),
            AnyView( CardIconValueView(icon: wifiImage(connected: connectedBoard.isWifiConnected, signalStrength: connectedBoard.wifiSignalStrength), value: (connectedBoard.formattedWifiName + " " + connectedBoard.formattedWifiSignalStrength)) )
        ]
    }
    private var environmentViews: [AnyView] {
        [
            AnyView( CardIconValueView(
                icon: Image("homeIconTemperature"),
                value: connectedBoard.formattedTemperature) ),
            AnyView( CardIconValueView(
                icon: Image("homeIconBarometer"),
                value: connectedBoard.formattedPressure) ),
            AnyView( CardIconValueView(
                icon: Image("homeIconLightbulb"),
                value: connectedBoard.formattedAmbientVisibleLight) ),
            AnyView( CardIconValueView(
                icon: Image("homeIconInfrared"),
                value: connectedBoard.formattedAmbientInfraredLight) )
        ]
    }
    private var ioViews: [AnyView] {
        // Two custom views; One for the LEDs and another for the Button.
        return [
            AnyView( LedStateIndicatorView(connectedBoard: connectedBoard) ),
            AnyView( ButtonStateIndicatorView(connectedBoard: connectedBoard) )
        ]
    }
    
    // MARK: Dynamic images used to convey state for some of the values
    
    func batteryImage(percentage: Int?, runningOnBattery: Bool?) -> Image {
        if let runningOnBattery = runningOnBattery {
            if !runningOnBattery { return Image("homeIconBatteryCharging") }
        }

        guard let percentage = percentage else {
            return Image("homeIconBatteryEmpty")
        }
        
        switch percentage {
        case 0:
            return Image("homeIconBatteryEmpty")
        case ...20: // Low
            return Image("homeIconBatteryLow")
        case ...50: // Quarter
            return Image("homeIconBatteryQuarter")
        case ...75: // Half
            return Image("homeIconBatteryHalf")
        default: // Full
            return Image("homeIconBatteryFull")
        }
    }
    
    func acImage(runningOnBattery: Bool?) -> Image {
        guard let runningOnBattery = runningOnBattery else {
            return Image("homeIconAcPluggedIn")
        }

        return runningOnBattery ? Image("homeIconAcNotPluggedIn") : Image("homeIconAcPluggedIn")
    }
    
    func wifiImage(connected: Bool, signalStrength: Int?) -> Image {
        
        guard let signalStrength = signalStrength, connected else {
            return Image("homeIconWifiOff")
        }

        var wifiOverlayIcon: UIImage
                
        switch signalStrength {
        case ...(-75): // Low
            wifiOverlayIcon = UIImage.template(named: "homeIconWifiLow", tintColor: .tmoMagenta)
        case ...(-65): // Medium
            wifiOverlayIcon = UIImage.template(named: "homeIconWifiMed", tintColor: .tmoMagenta)
        case ...(-55): // High
            wifiOverlayIcon = UIImage.template(named: "homeIconWifiHigh", tintColor: .tmoMagenta)
        default: // Excellent signal strength
            return Image("homeIconWifi")
        }
        
        // We add the tinted overlay icon on top of a gray full-strength wifi icon and return the resulting Image.
        let wifiIcon = UIImage.template(named: "homeIconWifi", tintColor: .tmoGray40)
        return Image(uiImage: wifiIcon.overlay(wifiOverlayIcon))
    }
    
    func cellSignalImage(connected: Bool) -> Image {
        return connected ? Image("homeIconSignalStrength") : Image("homeIconSignalStrengthNone")
    }
}

// MARK: - Constants
private struct Constants {
    static var backgroundColor = Color.tmoGray20
    static var cardSpacing: CGFloat = 24
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        
        HomeScreen()
            .previewDevice("iPhone SE (2nd generation)")
    }
}

