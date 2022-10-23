//
//  DetailScreen.swift
//  IoT Dev Kit Development
//
//  Created by Blake Bollinger on 2/23/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

struct DetailScreen: View {
    @State private var chartHighlightedDataIndex: Int? = nil
    private let minimumNumberOfChartPoints = 5
    
    private let measurementFormatter: MeasurementFormatter
    private let dateFormatter: DateFormatter
    private let title: String
    private let defaultUnit: Dimension
    private let secondaryUnit: Dimension?
    @State private var isUsingDefaultUnit: Bool = true
    /// The unit to use for the UI based on the `isUsingDefaultUnit` property. Returns the `defaultUnit` if `secondaryUnit` is `nil`.
    private var unitToUse: Dimension {
        isUsingDefaultUnit || secondaryUnit == nil ? defaultUnit : secondaryUnit!
    }
    /// The unit postfix to use for the UI based on the `isUsingDefaultUnit` property. Returns the `defaultUnit` symbol if `secondaryUnit` is `nil`.
    private var unitPostfixToUse: String {
        isUsingDefaultUnit || secondaryUnit == nil ? defaultUnit.symbol : secondaryUnit!.symbol
    }
    @ObservedObject private var history: DataHistory
    private var connectedBoard = Board.shared
    
    init(title: String, history: DataHistory, defaultUnit: Dimension, secondaryUnit: Dimension?) {
                
        self.title = title
        self.history = history
        self.defaultUnit = defaultUnit
        self.secondaryUnit = secondaryUnit
        
        measurementFormatter = MeasurementFormatter()
        measurementFormatter.unitStyle = .medium
        measurementFormatter.unitOptions = .providedUnit
        measurementFormatter.numberFormatter.numberStyle = .decimal
        measurementFormatter.numberFormatter.maximumFractionDigits = 2
        measurementFormatter.numberFormatter.minimumFractionDigits = 2
        
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Display the line chart visualization and its unit settings.
                    dataVisualization
                    
                    // Display the individual data readings in reverse order, which puts the newest reading on top.
                    dataReadings(title: "Recent readings", data: history.data.reversed())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .foregroundColor(Constants.foregroundColor)
            .background(Constants.backgroundColor)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(){
            ToolbarItem(placement: .navigationBarTrailing){
                Button (action: shareSheet) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private var dataVisualization : some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.cellCornerRadius, style: .continuous)
                .foregroundColor(Constants.tileBackgroundColor)
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    dataValue
                    
                    Spacer()
                    
                    // Only show the unit picker if there is a secondary unit.
                    if let secondaryUnit = secondaryUnit {
                        Picker("\(title) Scale", selection: $isUsingDefaultUnit) {
                            Group {
                                Text(defaultUnit.symbol)
                                    .tag(true)
                                Text(secondaryUnit.symbol)
                                    .tag(false)
                            }
                        }
                        .padding(.bottom)
                        .pickerStyle(.segmented)
                        .frame(width: 113)
                    }
                }
                                            
                // Get an array of the values for the selected unit.
                let data = history.data.map { convertedValue(reading: $0.value, toUnit: unitToUse) }

                // Only show max and min lines and labels if we have several values.
                let showMaxMinInChart = data.count > 1

                LineChartView(data: data, valueUnit: unitToUse, markerInnerColor: Constants.tileBackgroundColor, showZeroLine: true, showMaxAndMinValues: showMaxMinInChart, maxAndMinValuesColor: Constants.chartLabelColor, minimumNumberOfPoints: minimumNumberOfChartPoints, highlightInteractionEnabled: true, highlightedIndex: $chartHighlightedDataIndex)
                    .frame(height: 194)

                // The x-axis labels.
                HStack(alignment: .top) {
                    Text(oldestDateDisplay)
                        .font(.footnote)
                    Spacer()
                    Text(latestDateDisplay) // Keeps up to date using a timer.
                        .font(.footnote)
                        .onReceive(timer) { _ in self.latestDateDisplay = latestDateRelativeString() }
                }
                .foregroundColor(Constants.chartLabelColor)
            }
            .padding()
        }
    }
    
    private var dataValue : some View {
        VStack (alignment: .leading) {
            Text(String(sensorReading))
                .font(.title2.monospacedDigit())

            // If this is a highlighted value we also display the corresponding time.
            if let dataPoint = history.data.elementAt(index: chartHighlightedDataIndex) {
                Text("at \(dateFormatter.string(from:dataPoint.timestamp))")
                    .monospacedDigit()
                    .font(.footnote)
            }
        }
    }
    
    private func dataReadings(title: String, data: [DataHistory.DataPoint]) -> some View {
        return ZStack {
            RoundedRectangle(cornerRadius: Constants.cellCornerRadius, style: .continuous)
                .foregroundColor(Constants.tileBackgroundColor)
            
            LazyVStack(spacing: 12) {
                HStack {
                    Text(title)
                        .font(.title2)
                    Spacer()
                }
                .padding(.bottom, 6)
                
                ForEach(data) {
                    DataPointView(reading: formattedValue(reading: $0.value, toUnit: unitToUse), time: dateFormatter.string(from:$0.timestamp))
                }
            }
            .padding()
        }
    }
        
    private struct DataPointView: View {
        var reading: String
        var time: String
        
        var body: some View {
            HStack {
                
                Text(reading)
                    .font(.body.monospacedDigit())
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .allowsTightening(true)
                
                Spacer()
                
                Text(time)
                    .font(.body.monospacedDigit())
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .allowsTightening(true)
            }
        }
    }
    
    private var sensorReading: String {
        guard let dataPoint = history.data.last else { return "–" }

        // We default to using the latest value.
        var value = dataPoint.value

        // If a valid data point index is highlighted we use that value instead.
        if let highlightedDataPoint = history.data.elementAt(index: chartHighlightedDataIndex) {
            value = highlightedDataPoint.value
        }
        
        return formattedValue(reading: value, toUnit: unitToUse)
    }
    
    /// A string describing the relative time of the latest reading in the data history. May say "Now" or "5 seconds ago" etc. Updates are driven by a timer and the latestDateRelativeString() function.
    @State private var latestDateDisplay: String = ""

    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    private func latestDateRelativeString() -> String {
        guard let dataPoint = history.data.last else { return "" }
        
        let timeDiff = abs(dataPoint.timestamp.timeIntervalSinceNow)
        if timeDiff < 5 { return "Now" } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: dataPoint.timestamp, relativeTo: Date.now)
        }
    }

    /// A formatted string of the oldest time in the data history, or an empty string if there are not enough values in the data history to fill the chart.
    private var oldestDateDisplay: String {
        guard let dataPoint = history.data.first, history.data.count >= minimumNumberOfChartPoints else { return "" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        // Present a relative date with the time if needed. E.g. "Yesterday at 11:35 PM"
        if !Calendar.current.isDateInToday(dataPoint.timestamp) {
            dateFormatter.dateStyle = .medium
            dateFormatter.doesRelativeDateFormatting = true
        }

        return dateFormatter.string(from: dataPoint.timestamp)
    }

    /// Returns a `String` with the provided reading value converted to the specified unit.
    ///
    /// - parameter reading: The measurement value to convert.
    /// - parameter toUnit: The unit of measurement to convert to.
    /// - returns: A formatted string representing the value.
    private func formattedValue(reading: Double, toUnit: Dimension) -> String {

        let baseReading = Measurement(value: reading, unit: defaultUnit)
        return measurementFormatter.string(from: baseReading.converted(to: toUnit))
        
    }

    /// Returns a `Double` created by converting a reading value from the base unit for the sensor to the specified unit.
    /// For Temperature sensors the base unit is Celsius, for Pressure sensors the base unit is Kilopascal.
    ///
    /// - parameter reading: The measurement value to convert.
    /// - parameter toUnit: The unit of measurement to convert to.
    /// - returns: A converted value.
    private func convertedValue(reading: Double, toUnit: Dimension) -> Double {
        
        let baseReading = Measurement(value: reading, unit: defaultUnit)
        return baseReading.converted(to: toUnit).value
        
    }
    
    /// Presents the system share sheet for exporting the data readings in a CSV format.
    private func shareSheet() {
        var activityItemsStrings: [String] = []
        
        activityItemsStrings.append("\(title.capitalized) sensor readings from '\(connectedBoard.formattedBoardName)' in \(defaultUnit.symbol):")
        
        if history.data.isEmpty {
            activityItemsStrings.append("- no data to present -")
        } else {
            let isoDateFormatter = ISO8601DateFormatter()
            isoDateFormatter.timeZone = TimeZone.current
            
            var line : String
            for dataPoint in history.data {
                line = isoDateFormatter.string(from:dataPoint.timestamp) + ", " + String(dataPoint.value)
                activityItemsStrings.append(line)
            }
        }
        
        AppController.shared.presentShareSheet(activityItems: activityItemsStrings)
    }
}

extension UnitIlluminance {
    static let footCandle = UnitIlluminance(symbol: "fc", converter: UnitConverterLinear(coefficient: 10.7639))
    
    /*
     Watts Per Meter Squared is a tricky measurement because it is dependent on the wavelength of the light that is being measured. For our calculations in this app, we are using the conversion that has been specified by the firmware developers of the T-Mobile DevEdge IoT Developer Kit
     */
    static let incandescentWattsPerMeterSquared = UnitIlluminance(symbol: "W/m²", converter: UnitConverterLinear(coefficient: 638))
    static let incandescentMicroWattsPerCentimeterSquared = UnitIlluminance(symbol: "μW/cm²", converter: UnitConverterLinear(coefficient: 63800))
}

// MARK: - Constants
private struct Constants {
    static var foregroundColor = Color.tmoGray70
    static var chartLabelColor = Color.tmoGray60
    static var backgroundColor = Color.tmoGray20
    static var tileBackgroundColor = Color.tmoWhite
    static var cellCornerRadius: CGFloat = 4
}

struct DetailScreen_Previews: PreviewProvider {
    static var previews: some View {
        DetailScreen(title: "Temperature", history: Board.shared.temperatureHistory, defaultUnit: UnitTemperature.celsius, secondaryUnit: UnitTemperature.fahrenheit)
    }
}
