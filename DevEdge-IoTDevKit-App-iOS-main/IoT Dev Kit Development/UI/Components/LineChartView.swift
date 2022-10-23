//
//  LineChartView.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 2/17/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

/// A view for visualizing data provided as an array of Doubles.
struct LineChartView: View {
    private let data: [Double]
    private let valueUnit: Dimension?
    private let markerRadius: CGFloat
    private let markerColor: Color
    private let markerInnerRadius: CGFloat
    private let markerInnerColor: Color
    private let lineWidth: CGFloat
    private let lineColor: Color
    private let showZeroLine: Bool
    private let showMaxAndMinValues: Bool
    private let maxAndMinValuesColor: Color
    /// The minimum number of data points needed to fill the width of the chart.
    private let minimumNumberOfPoints: Int
    /// Support user interaction for highlighting of data points.
    /// This intercepts user interactions on the chart and updates the `highlightedIndex` binding to match the data point closest to the user's touch point.
    private let highlightInteractionEnabled: Bool
    /// The binding that tells the caller which index of the `data` array is being highlighted by the user, if any.
    @Binding private var highlightedIndex: Int?

    /// The highest value available in the data, or zero if no data is available.
    private let maxDataValue : Double
    /// The lowest value available in the data, or zero if no data is available.
    private let minDataValue : Double
    /// The highest value that fits in the chart.
    private let maxChartValue : Double
    /// The lowest value that fits in the chart.
    private let minChartValue : Double
    /// The span of values covered by the chart's y axis, from the lowest value to the highest value in the chart.
    private let yAxisValueRange : Double
    /// A GestureState flag for keeping track of whether the highlight gesture is in progress or not.
    @GestureState private var highlightGestureActiveState: Bool = false
    
    private let measurementFormatter: MeasurementFormatter
    private let hapticFeedback: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()
    
    /// A view that displays the provided `data` as a line chart.
    /// - Parameters:
    ///   - data: An `Array` of `Double`values to display as a line chart.
    ///   - valueUnit: The `Dimension` used to render the data values with their unit symbol. If `nil`, numbers are rendered without a descriptive symbol. Defaults to `nil`.
    ///   - lineColor: The `Color` used to draw the line representing the `data`. Defaults to the app's accent color.
    ///   - lineWidth: The stroke width, in points, used to draw the `line`. Defaults to `2`.
    ///   - markerColor: The `Color` used to draw the marker circle on the last data point, or the highlighted data point if one is selected. Defaults to the app's accent color.
    ///   - markerRadius: The radius used when drawing the marker circle. Defaults to `6`.
    ///   - markerInnerColor: The `Color` used for drawing a second, circle on the last data point, or the highlighted data point. Defaults to the system background color.
    ///   - markerInnerRadius: The radius used when drawing the second marker circle, this should be smaller than the `markerRadius`. Defaults to `4`.
    ///   - showZeroLine: Controls whether a horizontal line is drawn to indicate the where zero on the Y-axis is in the chart. Defaults to `false`.
    ///   - minChartValue: The lowest value that fits in the chart. Setting this to `0` would for example lock the chart to only show positive values. Defaults to `nil`, which adapts the chart to fit any value.
    ///   - maxChartValue: The highest value that fits in the chart. Defaults to `nil`, which adapts the chart to fit any value.
    ///   - showMaxAndMinValues: Controls whether annotations for the minimum and maximum values are shown above and below the line chart. Defaults to `false`
    ///   - maxAndMinValuesColor: The `Color` used for the max and min value annotations. Defaults to the primary system color.
    ///   - minimumNumberOfPoints: The minimum number of data points needed to fill the width of the chart. If `data` contains fewer values the chart's line is inset from the left, leaving a number of empty spots on the chart. Defaults to `5`.
    ///   - highlightInteractionEnabled: Controls whether the user can highlight data points in the chart by touching it and scrubbing back and forth. Defaults to `false`.
    ///   - highlightedIndex: A binding that signals the index of the highlightes data point, or `nil` if no data point is highlighted at the moment.
    /// - Returns: The view displaying the line chart.
    init(
         data: [Double],
         valueUnit: Dimension? = nil,
         lineColor: Color = Color.accentColor,
         lineWidth: CGFloat = 2,
         markerColor: Color = Color.accentColor,
         markerRadius: CGFloat = 6,
         markerInnerColor: Color = Color(UIColor.systemBackground),
         markerInnerRadius: CGFloat = 4,
         showZeroLine: Bool = false,
         minChartValue: Double? = nil,
         maxChartValue: Double? = nil,
         showMaxAndMinValues: Bool = true,
         maxAndMinValuesColor: Color = Color.primary,
         minimumNumberOfPoints: Int = 5,
         highlightInteractionEnabled: Bool = false,
         highlightedIndex: Binding<Int?> = Binding.constant(nil))
    {
        // Set the configuration values.
        self.data = data
        self.valueUnit = valueUnit
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.markerColor = markerColor
        self.markerRadius = markerRadius
        self.markerInnerColor = markerInnerColor
        self.markerInnerRadius = markerInnerRadius
        self.showZeroLine = showZeroLine
        self.showMaxAndMinValues = showMaxAndMinValues
        self.maxAndMinValuesColor = maxAndMinValuesColor
        self.minimumNumberOfPoints = minimumNumberOfPoints
        self.highlightInteractionEnabled = highlightInteractionEnabled
        self._highlightedIndex = highlightedIndex

        // Prepare the charting values.
        self.maxDataValue = data.max() ?? 0
        self.minDataValue = data.min() ?? 0

        // Let the max and min data values define the chart's y-axis range, unless provided with max and min values.
        var maxChartValueCandidate = maxDataValue
        var minChartValueCandidate = minDataValue
        if let maxChartValue = maxChartValue { maxChartValueCandidate = maxChartValue }
        if let minChartValue = minChartValue { minChartValueCandidate = minChartValue }
        
        // Ensure the range differs a little so we don't have a zero or near zero y-axis span.
        if maxChartValueCandidate - minChartValueCandidate < 0.1 {
            let middleValue = (maxChartValueCandidate + minChartValueCandidate) / 2.0
            
            maxChartValueCandidate = middleValue + 0.05
            minChartValueCandidate = middleValue - 0.05
        }
        
        self.maxChartValue = maxChartValueCandidate
        self.minChartValue = minChartValueCandidate
        
        self.yAxisValueRange = self.maxChartValue - self.minChartValue
        
        // Prepare the number and unit formatting.
        measurementFormatter = MeasurementFormatter()
        measurementFormatter.unitStyle = .medium
        measurementFormatter.unitOptions = .providedUnit
        measurementFormatter.numberFormatter.numberStyle = .decimal
        measurementFormatter.numberFormatter.maximumFractionDigits = 1
        measurementFormatter.numberFormatter.minimumFractionDigits = 1
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            if showMaxAndMinValues { annotation(prefix: "Max ", value: maxDataValue) }
            
            GeometryReader { geometry in
                let viewSize = geometry.size
                Group {
                    if showMaxAndMinValues {
                        horizontalLine(for: maxDataValue, viewSize: viewSize)
                        horizontalLine(for: minDataValue, viewSize: viewSize)
                    }
                    if showZeroLine { horizontalLine(for: 0, dashed: true, viewSize: viewSize) }
                    chartLine(viewSize: viewSize)
                    chartMarkers(viewSize: viewSize)
                }
                .contentShape(Rectangle())  // Make the gesture below work on transparent parts of the view.
                .gesture( highlightGesture(viewSize) )
            }
            .padding(max(self.markerRadius, self.lineWidth / 2.0))
            .padding(.horizontal) // This additional padding leaves areas on the side of the chart that are unaffected by the highlight gesture. This helps with vertical scrolling in case the chart is in a scroll view.
            .clipped()

            if showMaxAndMinValues { annotation(prefix: "Min ", value: minDataValue) }
        }
        .onChange(of: highlightGestureActiveState) { isActive in
            if !isActive {
                // The highlighting gesture ended or was cancelled.
                self.highlightedIndex = nil
            }
        }
    }
}

// MARK: - ViewBuilders
private extension LineChartView {
    @ViewBuilder func chartLine(viewSize: CGSize) -> some View {
        Path { path in
            for index in data.indices {

                let xPosition = xPosition(index: index, viewWidth: viewSize.width)

                let yPosition = yPosition(value: data[index], viewHeight: viewSize.height)

                if index == 0 {
                    path.move(to: CGPoint(x:xPosition, y:yPosition))
                } else {
                    path.addLine(to: CGPoint(x: xPosition, y: yPosition))
                }
            }
        }
        .stroke(lineColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }
    
    @ViewBuilder func chartMarkers(viewSize: CGSize) -> some View {
        if let lastIndex = data.indices.last {

            // Because self.highlightedIndex is a binding we need to ensure it holds a valid index for our current data
            // set. If it does not we fall back to marking the _latest_ data point in the set.
            let highlightedIndexIsValid = self.highlightedIndex != nil ? self.data.indices.contains(self.highlightedIndex!) : false
            let indexToMark = highlightedIndexIsValid ? self.highlightedIndex! : lastIndex
            
            // If the user is highlighting a value, we indicate the data point location with a vertical line.
            if highlightedIndexIsValid {
                let xHighlightPosition = xPosition(index: indexToMark, viewWidth: viewSize.width)
                Path { path in
                    path.move(to: CGPoint(x: xHighlightPosition, y: 0))
                    path.addLine(to: CGPoint(x: xHighlightPosition, y: viewSize.height))
                }
                .stroke(.secondary, style: StrokeStyle(lineWidth: 1, lineCap: .butt))
            }
            
            let xMarkPosition = xPosition(index: indexToMark, viewWidth: viewSize.width) - markerRadius
            let yMarkPosition = yPosition(value: data[indexToMark], viewHeight: viewSize.height) - markerRadius
            
            Circle()
                .fill(markerColor)
                .frame(width: markerRadius * 2, height: markerRadius * 2)
                .overlay {
                    Circle()
                        .fill(markerInnerColor)
                        .frame(width: markerInnerRadius * 2, height: markerInnerRadius * 2)
                }
                .offset(x: xMarkPosition, y: yMarkPosition)
        }
    }
    
    @ViewBuilder func horizontalLine(for value: Double, dashed: Bool = false, viewSize: CGSize) -> some View {
        let yPosition = yPosition(value: value, viewHeight: viewSize.height)
        let dashPattern: [CGFloat] = dashed ? [5, 2, 2, 2] : []
        
        Path { path in
            path.move(to: CGPoint(x: -1000, y: yPosition))
            path.addLine(to: CGPoint(x: viewSize.width + 1000, y: yPosition))
        }
        .stroke(Color(uiColor: .separator),
                style: StrokeStyle(lineWidth: 1, lineCap: .butt, dash: dashPattern))

    }
    
    @ViewBuilder func annotation(prefix: String, value: Double) -> some View {
        Text("\(prefix)\(formattedValue(reading:value, unit:valueUnit) ?? "–")")
            .font(.footnote).monospacedDigit()
            .foregroundColor(maxAndMinValuesColor)
            .padding(.vertical, markerRadius) // Move the annotation out of the way of the marker, in case the newest value is either the maximum or minimum value.
    }
}

// MARK: - Helper methods
private extension LineChartView {
    func yPosition(value: Double, viewHeight: CGFloat) -> CGFloat {
      return (1 - CGFloat((value - minChartValue) / yAxisValueRange)) * viewHeight
    }
    
    func xPosition(index: Int, viewWidth: CGFloat) -> CGFloat {
        // Handle the case when there are too few datapoints and we don’t want to fill the entire chart width.
        let totalPoints = data.count > minimumNumberOfPoints ? data.count : minimumNumberOfPoints
        
        let stepsFromLast = CGFloat(data.count - 1 - index)
        let stepLength = viewWidth / CGFloat(totalPoints - 1)
        
        return viewWidth - stepsFromLast * stepLength
    }
    
    func indexFor(xPosition: CGFloat, viewWidth: CGFloat) -> Int {
        // Handle the case when there are too few datapoints and we don’t want to fill entire chart width.
        let totalPoints = data.count > minimumNumberOfPoints ? data.count : minimumNumberOfPoints
        
        let stepLength = viewWidth / CGFloat(totalPoints - 1)
        var index = Int(round(xPosition/stepLength))
        
        // Compensate in case the number of datapoints is less than the minimum allowed.
        let missingDataPoints = minimumNumberOfPoints - data.count
        if missingDataPoints > 0 {
            index -= missingDataPoints
        }
        
        // Ensure the found index is not out of range.
        index = max(index, 0)
        index = min(index, data.count - 1)
        return index
    }
    
    func highlightGesture(_ viewSize: CGSize) -> GestureStateGesture<DragGesture, Bool>? {

        if !highlightInteractionEnabled { return nil } // No gesture needed if interaction is disabled.
        
        // We use a pretty sensitive drag gesture to detect user interaction almost immediately after they start dragging on the view, while trying to minimize interference with the parent view's scrolling behavior.
        return DragGesture(minimumDistance: 16)
            .updating($highlightGestureActiveState) { value, gestureActiveState, transaction in
                
                // NOTE: The gesture state will be set to false automatically when the gesture ends or is cancelled.
                gestureActiveState = true
                
                // Update the highlighted index binding if necessary.
                let index = indexFor(xPosition: value.location.x, viewWidth: viewSize.width)
                if index != self.highlightedIndex {
                    // Use haptic feedback to indicate that the highlighted data point index changed.
                    hapticFeedback.selectionChanged()
                    // We tell the Taptic Engine we are likely to trigger more selection changes in the short term.
                    // This keeps the Taptic Engine active and reduces haptic feedback latency. To conserve energy the
                    // Taptic Engine returns to an idle state after a few seconds if it hasn't been triggered again.
                    hapticFeedback.prepare()
                    DispatchQueue.main.async {
                        self.highlightedIndex = index
                    }
                }
            }
    }
    
    /// Returns a `String` with the provided `reading` value presented as the specified `unit`. E.g. "23.4ºC" or "1005.6 mbar".
    ///
    /// - parameter reading: The measurement value to format.
    /// - parameter unit: The unit of measurement to represent the value as. If `nil` the returned `String` will not contain unit symbols.
    /// - returns: A formatted string representing the value. Or `nil` if unable to provide a formatted string.
    private func formattedValue(reading: Double, unit: Dimension? = nil) -> String? {
        
        // If no unit was provided we only format the numerical value itself.
        guard let unit = unit else {
            return measurementFormatter.numberFormatter.string(from: NSNumber(value: reading))
        }

        let baseReading = Measurement(value: reading, unit: unit)
        return measurementFormatter.string(from: baseReading)
    }
}

// MARK: - Previews
struct LineChartView_Previews: PreviewProvider {
    static var previews: some View {
        LineChartView(data: [15.0, 12.4, 11.7, 45.1, 35.2, 37.9, 24.1, 27.5], valueUnit: UnitTemperature.celsius)
            .background(.quaternary)
            .padding()
        
    }
}
