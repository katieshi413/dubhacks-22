//
//  Board.swift
//  Dev Kit
//
//  Created by Blake Bollinger on 6/10/21.
//  Copyright 2022 T-Mobile USA, Inc
//

import CoreLocation

/// When the app is connected to a board via Bluetooth, the `Board.shared` instance provides information on the state of the board for presentation in the UI.
/// If no board is connected, placeholder values are used to indicate the lack of available information.
class Board: Identifiable, ObservableObject {
    
    // Singleton pattern with private initializer
    static let shared = Board()
    private init() { }
    
    // MARK: - Properties
    let bluetoothManager = BluetoothManager()

    /// The maximum number of historical sensor values to keep for each stored sensor.
    /// The user can change this value from the app's settings screen in the system Settings.app.
    @SettingsValue(key: "sensor_cache_size", default: 60)
    private static var sensorCacheSize: Int

    var boardName: String = "Board 1"
    var boardIMEI: String = "-"
    var boardID: UUID? { bluetoothManager.connectedPeripheral?.identifier }

    @Published var isConnected: Bool = false {
        didSet { resetValues() } // Resets stored sensor values on both connection and disconnection events.
    }
    @Published var isBeingViewed: Bool = false
    
    @Published var isOnBattery: Bool? = nil
    @Published var batteryPercentage: Int? = nil
    
    @Published var temperature: Double? {
        didSet { if let newValue = temperature { self.temperatureHistory.append(newValue) } }
    }
    @Published var pressure: Double? {
        didSet { if let newValue = pressure { self.pressureHistory.append(newValue) } }
    }
    @Published var ambientVisibleLight: Double? {
        didSet { if let newValue = ambientVisibleLight { self.ambientVisibleLightHistory.append(newValue) } }
    }
    @Published var ambientInfraredLight: Double? {
        didSet { if let newValue = ambientInfraredLight { self.ambientInfraredLightHistory.append(newValue) } }
    }

    @Published var buttonPressed = false
    @Published var redLedOn = false
    @Published var greenLedOn = false
    @Published var blueLedOn = false
    @Published var whiteLedOn = false
    @Published var buzzerOn = false
    
    @Published var xAcceleration: Float = 0 {
        didSet { self.accelerationHistoryX.append(Double(xAcceleration)) }
    }
    @Published var yAcceleration: Float = 0 {
        didSet { self.accelerationHistoryY.append(Double(yAcceleration)) }
    }
    @Published var zAcceleration: Float = 0 {
        didSet { self.accelerationHistoryZ.append(Double(zAcceleration)) }
    }
    
    let boardLocation: BoardLocation = BoardLocation()
    
    @Published var cellSignalStrength: Int? = nil
    
    @Published var wifiName: String? = nil
    @Published var wifiSignalStrength: Int? = nil
    
    // NOTE: A Wi-Fi signal strength of 0 indicates the board is not connected to wifi.
    var isWifiConnected: Bool { wifiSignalStrength != nil && wifiSignalStrength != 0 }
    // NOTE: A Cellular signal strength of 0 indicates the board is not connected to the cellular network.
    var isCellNetworkConnected: Bool { cellSignalStrength != nil && cellSignalStrength != 0 }

    // MARK: - Sensor value history storage.
    let temperatureHistory: DataHistory = DataHistory(maxCount: Board.sensorCacheSize)
    let pressureHistory: DataHistory = DataHistory(maxCount: Board.sensorCacheSize)
    let ambientVisibleLightHistory: DataHistory = DataHistory(maxCount: Board.sensorCacheSize)
    let ambientInfraredLightHistory: DataHistory = DataHistory(maxCount: Board.sensorCacheSize)
    let accelerationHistoryX: DataHistory = DataHistory(maxCount: Board.sensorCacheSize)
    let accelerationHistoryY: DataHistory = DataHistory(maxCount: Board.sensorCacheSize)
    let accelerationHistoryZ: DataHistory = DataHistory(maxCount: Board.sensorCacheSize)
    
    // MARK: - Formatted strings representing the board information and sensor values, for presentation in the UI.
    var formattedBoardName: String { isConnected ? boardName : "Not Connected" }
    var formattedBatteryLevel: String { batteryPercentage != nil ? "\(batteryPercentage!)%" : "-" }
    var formattedTemperature: String { temperature != nil ? "\(String(format: "%.0f", temperature!))ºC" : "-" }
    var formattedPressure: String { pressure != nil ? "\(String(format: "%.0f", pressure!)) mbar" : "-" }
    var formattedAmbientVisibleLight: String { ambientVisibleLight != nil ? "\(String(format: "%.0f", ambientVisibleLight!)) lx" : "-" }
    var formattedAmbientInfraredLight: String { ambientInfraredLight != nil ? "\(String(format: "%.0f", ambientInfraredLight!)) W/m²" : "-" }
    var formattedLightStatus: String {
        let ledStatus = (redLedOn || greenLedOn || blueLedOn || whiteLedOn) ? "LED on" : "LED off"
        return isConnected ? ledStatus : "-"
    }
    var formattedAcStatus: String {
        var acStatus = "-"
        if let isOnBattery = isOnBattery {
            acStatus = isOnBattery ? "Not plugged in" : "Plugged in"
        }
        return acStatus
    }
    var formattedWifiName: String {
        if let wifiName = wifiName, isWifiConnected {
            // Wifi is connected and we have a wifi name to show.
            return wifiName
        } else if isConnected {
            // The board is connected over BLE, but it's not connected to wifi.
            return "Not Connected"
        }
        
        // There is no Wifi connection status to show.
        return "-"
    }
    var formattedWifiSignalStrength: String {
        // NOTE: This signal strength string is meant to be shown alongside the formattedWifiName in the UI.
        // E.g.: My network (-55 dBm)
        
        if let wifiSignalStrength = wifiSignalStrength, wifiSignalStrength != 0 {
            return "(\(wifiSignalStrength) dBm)" // We have wifi signal strength information to show.
        }
        
        return "" // There is no wifi signal strength to show.
    }
    var formattedCellSignalStrength: String {
        if let cellSignalStrength = cellSignalStrength {
            return "\(cellSignalStrength) dBm" // We have cell signal strength information to show.
        }
        
        return "-" // There is no cell signal strength to show.
    }
    
    // MARK: - Functions
    func updateLed() {
        bluetoothManager.setLED(redLedOn: redLedOn, greenLedOn: greenLedOn, blueLedOn: blueLedOn, whiteLedOn: whiteLedOn, buzzerOn: buzzerOn)
    }
    
    func setValueNotificationsForDeviceMotion(enabled: Bool) {
        bluetoothManager.setValueNotifications(enabled: enabled, for: .acceleration)
    }

    private func resetValues() {
        boardIMEI = "-"
        
        isOnBattery = nil
        batteryPercentage = nil
        temperature = nil
        temperatureHistory.reset(maxCount: Board.sensorCacheSize)
        pressure = nil
        pressureHistory.reset(maxCount: Board.sensorCacheSize)
        ambientVisibleLight = nil
        ambientVisibleLightHistory.reset(maxCount: Board.sensorCacheSize)
        ambientInfraredLight = nil
        ambientInfraredLightHistory.reset(maxCount: Board.sensorCacheSize)
        buttonPressed = false
        redLedOn = false
        blueLedOn = false
        greenLedOn = false
        whiteLedOn = false
        xAcceleration = 0.0
        yAcceleration = 0.0
        zAcceleration = 0.0
        accelerationHistoryX.reset(maxCount: Board.sensorCacheSize)
        accelerationHistoryY.reset(maxCount: Board.sensorCacheSize)
        accelerationHistoryZ.reset(maxCount: Board.sensorCacheSize)
        boardLocation.reset()
        wifiName = nil
        wifiSignalStrength = nil
        cellSignalStrength = nil
    }
}

/// A class for storing whether a location reading for a Board is available, and what the corresponding coordinate, elevation, and timestamp is.
class BoardLocation: ObservableObject {
    
    enum LocationState {
        case located(latitude: Double, longitude: Double, elevation: Double?, timestamp: Date = Date.now)
        case undetermined
        
        func coordinate() -> CLLocationCoordinate2D? {
            switch self {
            case .located(let latitude, let longitude, _, _):
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            case .undetermined:
                return nil
            }
        }
    }
    
    @Published private(set) var state = LocationState.undetermined
    
    /// Sets the location state to the provided state.
    func update(_ newState: LocationState) {
        self.state = newState
    }
    
    /// Sets the location state back to the undetermined state.
    func reset() {
        self.state = LocationState.undetermined
    }
}

/// A class for storing a limited number of the most recent data points.
/// Note: This is not a very efficient data structure since every append has to iterate through the entire array to remove to oldest value before appending a new value.
class DataHistory: ObservableObject {

    struct DataPoint: Identifiable {
        let id = UUID()
        
        let value: Double
        let timestamp: Date
    }
    
    private(set) var maxCount: Int
    @Published private(set) var data = [DataPoint]()
    
    init(maxCount: Int) {
        self.maxCount = maxCount
    }
    
    /// Adds a new value as a `DataPoint` at the end of the `data` array.
    /// Removes the oldest value if the array already contains `maxCount` values.
    /// - Complexity: O(*n*) on average, over many calls to `append(_:)` on the
    ///   same `DataHistory` instance.
    func append(_ value: Double) {
        let dataPoint = DataPoint(value: value, timestamp: Date())
        
        if data.count == maxCount {
            data.removeFirst()
        }
        
        data.append(dataPoint)
    }
    
    /// Removes alla data points and updates the `maxCount` setting.
    func reset(maxCount: Int) {
        self.maxCount = maxCount
        self.data.removeAll()
    }
}
