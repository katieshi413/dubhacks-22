//
//  EnvironmentScreen.swift
//  IoT Dev Kit Development
//
//  Created by Geol Kim on 2/14/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

struct EnvironmentScreen: View {
    private var connectedBoard = Board.shared
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 24) {
                    EnvironmentNavigationCell(sensor: .Temperature, title: "Temperature", icon: Image("homeIconTemperature"), connectedBoard: connectedBoard, dataHistory: connectedBoard.temperatureHistory, defaultUnit: UnitTemperature.celsius, secondaryUnit: UnitTemperature.fahrenheit)
                    EnvironmentNavigationCell(sensor: .AirPressure, title: "Air Pressure", icon: Image("homeIconBarometer"), connectedBoard: connectedBoard, dataHistory: connectedBoard.pressureHistory, defaultUnit: UnitPressure.millibars, secondaryUnit: UnitPressure.inchesOfMercury)
                    EnvironmentNavigationCell(sensor: .AmbientVisibleLight, title: "Visible Light", icon: Image("homeIconLightbulb"), connectedBoard: connectedBoard, dataHistory: connectedBoard.ambientVisibleLightHistory, defaultUnit: UnitIlluminance.lux, secondaryUnit: UnitIlluminance.footCandle)
                    EnvironmentNavigationCell(sensor: .AmbientInfraredLight, title: "Infrared Light", icon: Image("homeIconInfrared"), connectedBoard: connectedBoard, dataHistory: connectedBoard.ambientInfraredLightHistory, defaultUnit: UnitIlluminance.incandescentWattsPerMeterSquared)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .background(Constants.backgroundColor)
        }
        .navigationTitle("Environment")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EnvironmentNavigationCell: View {
    
    enum Sensor {
        case Temperature
        case AirPressure
        case AmbientVisibleLight
        case AmbientInfraredLight
    }
    
    let sensor: Sensor
    var title: String
    var icon: Image
    var connectedBoard: Board
    @ObservedObject var dataHistory: DataHistory
    var defaultUnit: Dimension
    var secondaryUnit: Dimension?
    
    private var value: String {
        switch sensor {
        case .Temperature:
            return connectedBoard.formattedTemperature
        case .AirPressure:
            return connectedBoard.formattedPressure
        case .AmbientVisibleLight:
            return connectedBoard.formattedAmbientVisibleLight
        case .AmbientInfraredLight:
            return connectedBoard.formattedAmbientInfraredLight
        }
    }
    private var sparkLineValues: [Double] { dataHistory.data.map { $0.value } }
    private var contentViews: [AnyView] { [AnyView( CardIconValueView(icon: icon, value: value) )] }
    
    var body: some View {
        NavigationLink(destination: DetailScreen(title: title, history: dataHistory, defaultUnit: defaultUnit, secondaryUnit: secondaryUnit))
        {
            // A CardView, with a LineChartView overlaid in the corner.
            CardView(title: title, showChevron: true, contentViews: contentViews)
                .overlay(alignment: .bottomTrailing) {
                    LineChartView(data: sparkLineValues, markerRadius: 1, markerInnerRadius:0, showMaxAndMinValues: false)
                        .frame(width: 112, height: 30)
                        .padding([.trailing, .bottom])
                }
        }
    }
}

// MARK: - Constants
private struct Constants {
    static var backgroundColor = Color.tmoGray20
}


struct EnvironmentScreen_Previews: PreviewProvider {
    static var previews: some View {
        EnvironmentScreen()

        EnvironmentScreen()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
            .previewInterfaceOrientation(.portrait)
    }
}
