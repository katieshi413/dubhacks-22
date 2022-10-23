//
//  MotionScreen.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 11/16/21.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

/// A view that shows the accelerometer readings from the connected Bluetooth board and illustrates them using line charts and a 3D model of the DevEdge board.
struct MotionScreen: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var connectedBoard = Board.shared
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    ScrollView {
                        Text("See your dev kit move in real-time")
                            .font(.title2)
                            .allowsTightening(true)
                            .multilineTextAlignment(.center)
                            .padding(.top, Constants.topBottomPadding)
                        
                        SceneModelView(manager: MotionSceneManager(board: connectedBoard))
                            .frame(minHeight: 120.0, maxHeight: 300.0)
                            .aspectRatio(16.0/9.0, contentMode: .fit)
                            .padding(Constants.illustrationPadding)
                        
                        Measurements(geometry: geometry)
                            .padding(.bottom, Constants.topBottomPadding)
                        
                        AccelerationCharts()
                            .padding(.bottom)
                    }
                    .foregroundColor(.tmoGray70)
                    .onAppear {
                        Board.shared.setValueNotificationsForDeviceMotion(enabled: true)
                    }
                    .onDisappear {
                        Board.shared.setValueNotificationsForDeviceMotion(enabled: false)
                    }
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .navigationTitle("Motion")
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

    struct AccelerationCharts: View {
        @ObservedObject var historyX: DataHistory = Board.shared.accelerationHistoryX
        private var sparkLineValuesX: [Double] { historyX.data.map { $0.value } }
        @ObservedObject var historyY: DataHistory = Board.shared.accelerationHistoryY
        private var sparkLineValuesY: [Double] { historyY.data.map { $0.value } }
        @ObservedObject var historyZ: DataHistory = Board.shared.accelerationHistoryZ
        private var sparkLineValuesZ: [Double] { historyZ.data.map { $0.value } }

        private let markerRadius: CGFloat = 4.0
        private let markerInnerRadius: CGFloat = 2.0
        
        var body: some View {
            VStack(spacing: Constants.spacing) {
                LineChartView(data: sparkLineValuesX, markerRadius: markerRadius, markerInnerRadius: markerInnerRadius, showZeroLine: true, minChartValue: -12, maxChartValue: 12)
                    .overlay(Text("X axis").font(.footnote).padding(.vertical, markerRadius), alignment: .topLeading)

                LineChartView(data: sparkLineValuesY, markerRadius: markerRadius, markerInnerRadius: markerInnerRadius, showZeroLine: true, minChartValue: -12, maxChartValue: 12)
                    .overlay(Text("Y axis").font(.footnote).padding(.vertical, markerRadius), alignment: .topLeading)
                
                LineChartView(data: sparkLineValuesZ, markerRadius: markerRadius, markerInnerRadius: markerInnerRadius, showZeroLine: true, minChartValue: -12, maxChartValue: 12)
                    .overlay(Text("Z axis").font(.footnote).padding(.vertical, markerRadius), alignment: .topLeading)
            }
            .frame(minHeight: 420)
            .padding(.horizontal)
        }
    }

    struct Measurements: View {
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        var geometry: GeometryProxy
        
        var body: some View {
            let content = Group {
                AccelerationMeasurements()
                    .layoutPriority(1)
                    .fixedSize()
            }
            
            // Adapt layout to better fit content when using accessibility text sizes or narrow displays.
            let narrowSpace = geometry.size.width < 350
            let useVerticalLayout = narrowSpace ||  dynamicTypeSize.isAccessibilitySize && horizontalSizeClass == UserInterfaceSizeClass.compact
            
            HStack(alignment: .top, spacing: Constants.spacing) {
                if useVerticalLayout {
                    VStack(alignment: .center, spacing: Constants.spacing) {
                        content
                    }
                    .padding(.horizontal)
                } else {
                    content
                        .layoutPriority(1)
                }
            }
        }
        
        struct AccelerationMeasurements: View {
            @ObservedObject var connectedBoard = Board.shared
            private let numberFormatter: NumberFormatter
            
            init() {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 2
                formatter.minimumFractionDigits = 2
                self.numberFormatter = formatter
            }
            
            var body: some View {
                VStack {
                    Text("Accelerometer (m/s²)")
                        .font(.title2)
                        .allowsTightening(true)
                    Spacer(minLength: Constants.spacing)
                    MeasurementView(label: "X:", value:
                                        numberFormatter.string(from: NSNumber(value: connectedBoard.xAcceleration)) ?? "-")
                    MeasurementView(label: "Y:", value:
                                        numberFormatter.string(from: NSNumber(value: connectedBoard.yAcceleration)) ?? "-")
                    MeasurementView(label: "Z:", value:
                                        numberFormatter.string(from: NSNumber(value: connectedBoard.zAcceleration)) ?? "-")
                }
            }
        }
        
        struct MeasurementView: View {
            var label: String
            var value: String
            
            var body: some View {
                HStack {
                    Text(label)
                        .font(.system(.title2, design: .monospaced))
                    Spacer(minLength: Constants.spacing)
                    Text(value)
                        .font(.title2)
                        .monospacedDigit()
                }
            }
        }
    }
    
    struct MeasurementsValues {
        var accelerationX: String
        var accelerationY: String
        var accelerationZ: String
    }
}

// MARK: - Constants
private struct Constants {
    static var spacing: CGFloat = 24
    static var illustrationPadding: CGFloat = 32
    static var topBottomPadding: CGFloat = 32
}

struct MotionScreen_Previews: PreviewProvider {
    static var previews: some View {
        MotionScreen()
        MotionScreen()
            .environment(\.sizeCategory, .accessibilityExtraLarge)
    }
}
