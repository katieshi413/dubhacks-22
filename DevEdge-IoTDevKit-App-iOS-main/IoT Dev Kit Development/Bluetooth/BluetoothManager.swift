//
//  BluetoothManager.swift
//  Dev Kit
//
//  Created by Blake Bollinger on 7/20/21.
//  Copyright 2022 T-Mobile USA, Inc
//

import Foundation
import CoreBluetooth

public class BluetoothManager: NSObject, ObservableObject {
    
    /// An enum of DevEdge board sensors that support notifying the connected app over Bluetooth when their values change.
    enum NotifyingSensors {
        case acceleration
        case button
        // TODO: Consider adding .battery and .location cases if the DevEdge board's firmware ends up supporting those.
    }
    
    static let bluetoothStateDidChangeNotification = NSNotification.Name(rawValue: "bluetoothStateDidChangeNotification")
    static let bluetoothDidConnectPeripheralNotification = NSNotification.Name(rawValue: "bluetoothDidConnectPeripheralNotification")
    private let unknownPeripheralNamePlaceholder = "Unknown"
    
    /// The name prefix to use when filtering the list of detected Bluetooth peripherals. If empty string, no filtering is done.
    /// The user can change this value from the app's settings screen in the system Settings.app.
    @SettingsValue(key: "allowed_bluetooth_accessory_prefix", default: "")
    private var allowedBluetoothAccessoryPrefix: String
    
    /// The interval in seconds between each attempt at polling for sensor values from the connected Bluetooth peripheral.
    /// The user can change this value from the app's settings screen in the system Settings.app.
    @SettingsValue(key: "sensor_poll_interval", default: 2)
    private var pollInterval: Int
    private var pollingTimer: Timer?
    
    /// The array of Bluetooth characteristics to poll for when the `pollingTimer` fires.
    private var pollCharacteristics: [CBCharacteristic] = []
    
    /// The identifiers for the Bluetooth characteristics we expect to poll for.
    private let pollCharacteristicIdentifiers = [
        CBUUID.TemperatureCharacteristic,
        CBUUID.PressureCharacteristic,
        CBUUID.IlluminanceCharacteristic,
        CBUUID.AmbientIRCharacteristic,
        CBUUID.PowerSourceCharacteristic,       // This should ideally be notified instead of polled.
        CBUUID.DebugLogCharacteristic,          // This should perhaps be notified instead of polled.
        CBUUID.CellularSignalCharacteristic,
        CBUUID.WifiNameCharacteristic,          // This should ideally be notified instead of polled.
        CBUUID.WifiSignalCharacteristic,
        CBUUID.BatteryLevelCharacteristic,      // This should perhaps be notified instead of polled.
        CBUUID.LocationAndSpeedCharacteristic
    ]
    
    private var centralManager: CBCentralManager?
    
    // Flag to indicate if the board's acceleration sensor should be notifying the app about changes.
    private var shouldBeNotifyingForAcceleration: Bool = false
    
    private var ledCharacteristic: CBCharacteristic? // This handles both LED values as well as the audio buzzer value.
    private var accelerationCharacteristic: CBCharacteristic? {
        didSet {
            // Start or stop the notifications about changes to the sensor values, based on the shouldBeNotifyingForAcceleration flag
            self.setValueNotifications(enabled: shouldBeNotifyingForAcceleration, for: .acceleration)
        }
    }
    private var buttonCharacteristic: CBCharacteristic? {
        didSet {
            // Start the notifications about changes to the button state.
            self.setValueNotifications(enabled: true, for: .button)
        }
    }
    
    
    @Published var isBluetoothAvailable = false
    @Published var detectedPeripherals = [CBPeripheral]()
    @Published var connectedPeripheral: CBPeripheral?
    @Published var isScanningForDevices = false
    
    var connectionState: CBPeripheralState { connectedPeripheral?.state ?? CBPeripheralState.disconnected }
    
    override init() {
        super.init()
        
        if CBCentralManager.authorization == .allowedAlways {
            isBluetoothAvailable = true
            initBluetooth()
        }
    }

    func initBluetooth() {
        if centralManager != nil { return } // Early return if Bluetooth is already initialized.
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        // Trigger the authorization alert if not already accepted or denied.
        if CBCentralManager.authorization == .notDetermined {
            initBluetooth()
        }

        // Reset the list of peripherals to empty here so we get a list of only devices detected since scanning began.
        detectedPeripherals = [CBPeripheral]()

        isScanningForDevices = true // Set flag to indicate that we intend to be scanning for devices.

        if let centralManager = centralManager, centralManager.state == .poweredOn {

            centralManager.scanForPeripherals(withServices: nil, options: nil)
            print("BluetoothManager has begun scanning")
        }
    }
    
    func stopScanning() {
        isScanningForDevices = false
        centralManager?.stopScan()
        print("BluetoothManager has stopped scanning")
    }
    
    /// Start a connection attempt to a peripheral.
    /// - parameter peripheral: The specific peripheral to connect to.
    func attemptConnectionTo(_ peripheral: CBPeripheral) {
        // In case we are already attempting to connect to the device we don't start a new attempt.
        if peripheral.state == .connecting { return }
        
        // In case we are already connected to a device we disconnect before attempting to establish the new connection.
        if self.connectedPeripheral != nil { disconnect() }
        
        // Attempt to connect to the peripheral.
        self.connectedPeripheral = peripheral
        self.centralManager?.connect(peripheral, options: nil)

        // Start a timer to abort unsuccessful connection attempts after a few seconds.
        // NOTE: 30 seconds is a bit long for the time out, but due to pilot hardware (Summer 2022),
        // legitimate connections can take up to 30 seconds.
        Timer.scheduledTimer(withTimeInterval: TimeInterval(30.0), repeats: false) { [weak self] _ in
            guard let self = self else { return }

            // If the peripheral is still attempting to connect, abort the attempt.
            if (peripheral.state == .connecting) {
                self.disconnect(peripheral: peripheral)
                log("Connection attempt to '\(peripheral.identifier.uuidString)' timed out")
            }
        }
    }
    
    /// Disconnect or cancel a peripheral's connection.
    /// - parameter peripheral: The specific peripheral to disconnect, or `nil` to disconnect the currently connected main peripheral.
    func disconnect(peripheral: CBPeripheral? = nil) {
        guard let disconnectionPeripheral: CBPeripheral = peripheral ?? connectedPeripheral else { return }
        if disconnectionPeripheral == connectedPeripheral { stopPollingForValues() } // Stop polling if disconnecting our current main peripheral.
        self.centralManager?.cancelPeripheralConnection(disconnectionPeripheral)
    }
    
    /// Writes the state for the LEDs and Buzzer to the board according to the given parameters.
    func setLED(redLedOn: Bool, greenLedOn: Bool, blueLedOn: Bool, whiteLedOn: Bool, buzzerOn: Bool) {
        guard let ledCharacteristic = ledCharacteristic, let connectedPeripheral = connectedPeripheral else { return }
        
        var writeVal = ledAndBuzzerStateValue(redLedOn: redLedOn, greenLedOn: greenLedOn, blueLedOn: blueLedOn, whiteLedOn: whiteLedOn, buzzerOn: buzzerOn)
        
        print("Writing " + String(writeVal) + " to led characteristic")
        let intData = Data(bytes: &writeVal, count: MemoryLayout.size(ofValue: writeVal))
        connectedPeripheral.writeValue(intData, for: ledCharacteristic, type: .withResponse)
    }
    
    /// Enables or disables notifications from the board when the given sensor's value changes.
    func setValueNotifications(enabled: Bool, for sensor: NotifyingSensors) {
        var characteristic: CBCharacteristic?
        
        switch sensor {
        case .acceleration:
            characteristic = accelerationCharacteristic
            self.shouldBeNotifyingForAcceleration = enabled
        case .button:
            characteristic = buttonCharacteristic
        }
        
        if let characteristic = characteristic, characteristic.permissions.contains(.notify) {
            connectedPeripheral?.setNotifyValue(enabled, for: characteristic)
        }
    }
    
    /// Calculates the state value to send to the boards to set its LEDs and Buzzer according to the given parameters.
    private func ledAndBuzzerStateValue(redLedOn: Bool, greenLedOn: Bool, blueLedOn: Bool, whiteLedOn: Bool, buzzerOn: Bool) -> Int {
        var value = 0
        
        if redLedOn {
            value += 1
        }
        if greenLedOn {
            value += 2
        }
        if blueLedOn {
            value += 4
        }
        if whiteLedOn {
            value += 8
        }
        if buzzerOn {
            value += 16
        }
        
        return value
    }
    
    private func pollForValues() {
        if self.connectionState != .connected { return }
        
        guard let connectedPeripheral = connectedPeripheral else {
            print("Connected peripheral is 'nil'...skipping polling for values")
            return
        }
        
        print("Polling for \(pollCharacteristics.count) characteristics:")
        
        // Try to read values for the characteristics we decided to poll for.
        for characteristic in pollCharacteristics {
            if characteristic.permissions.contains(.read) {
                print("- \(characteristic.uuid.uuidString), properties: \(characteristic.properties.rawValue)")
                connectedPeripheral.readValue(for: characteristic)
            }
        }
    }
    
    private func startPollingForValues() {
        self.pollingTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(pollInterval), repeats: true) { [weak self] _ in
            self?.pollForValues()
        }
    }
    
    private func stopPollingForValues() {
        self.pollingTimer?.invalidate()
        self.pollingTimer = nil
    }
    
    private func peripheralMatchesRequiredCriteria(peripheral: CBPeripheral) -> Bool {
        guard let peripheralName = peripheral.name else { return false }
        return peripheralName.uppercased().hasPrefix(allowedBluetoothAccessoryPrefix.uppercased())
    }
}

// MARK: - CBCentralManagerDelegate methods
extension BluetoothManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // This is triggered after the user allows, or denies, Bluetooth authorization.
        
        isBluetoothAvailable = central.state == .poweredOn
        
        // Notify any observers that the Bluetooth state changed.
        NotificationCenter.default.post(name: BluetoothManager.bluetoothStateDidChangeNotification, object: self)
        
        // If we intended to already be scanning, but the CBCentralManager isn't currently scanning, we try to start the scan now.
        if isScanningForDevices && !central.isScanning {
            startScanning()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Early return because we are only looking for peripherals matching certain criteria.
        if !peripheralMatchesRequiredCriteria(peripheral: peripheral) { return }
        
        let peripheralName: String = peripheral.name ?? self.unknownPeripheralNamePlaceholder
        
        // Potentially interesting advertismentData keys to explore:
        // CBAdvertisementDataLocalNameKey - String
        // CBAdvertisementDataTxPowerLevelKey - NSNumber
        // CBAdvertisementDataIsConnectable - NSNumber
        // CBAdvertisementDataManufacturerDataKey - NSData
        
        var peripheralConnectable = "Not connectable"
        if let connectable = advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber {
            if connectable == NSNumber(value: 1) {
                peripheralConnectable = "Connectable"
            }
        }
        
        print("App discovered BLE peripheral: \(peripheralName) - \(peripheral.identifier.uuidString) - \(peripheralConnectable)")
        
        // Replace the existing peripheral with matching ID, or add it last in the list if no matching peripheral ID exists.
        let existingPeripheralIndex = detectedPeripherals.firstIndex(where: { $0.identifier == peripheral.identifier })
        if let existingPeripheralIndex = existingPeripheralIndex {
            detectedPeripherals.remove(at: existingPeripheralIndex)
            detectedPeripherals.insert(peripheral, at:existingPeripheralIndex) // Insert at the same index.
        } else {
            detectedPeripherals.append(peripheral)
        }
        
        print("  Number of detected peripherals: " + String(detectedPeripherals.count))
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
        Board.shared.boardName = peripheral.name ?? self.unknownPeripheralNamePlaceholder
        Board.shared.isConnected = self.connectionState == .connected
        
        // Notify any observers that a Bluetooth peripheral connection was established.
        NotificationCenter.default.post(name: BluetoothManager.bluetoothDidConnectPeripheralNotification, object: self)
        
        // Reset the list of charcteristics to poll for so it can be re-populated for this peripheral.
        pollCharacteristics = []
        self.startPollingForValues()
        log("App is connected to board '\(Board.shared.boardName)'")
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log("Disconnected")

        Board.shared.isConnected = self.connectionState == .connected
        
        peripheral.delegate = nil
        if connectedPeripheral == peripheral {
            stopPollingForValues()
            connectedPeripheral = nil
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log("App failed to connect to '\(peripheral.identifier.uuidString)' error: \(error?.localizedDescription ?? "nil")")
    }
}

// MARK: - CBPeripheralDelegate methods
extension BluetoothManager: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let peripheralName = peripheral.name ?? self.unknownPeripheralNamePlaceholder
        var debugMessage = "Did discover services for '\(peripheralName)'\n"
        
        guard let peripheralServices = peripheral.services else { return }
        
        for service in peripheralServices {
            debugMessage += "  Service: \(service.uuid)\n"

            // Using `nil` returns *all* of the service’s characteristics but can be slow.
            // If you know what characteristics you want to find for the service, supply an array of type [CBUUID].
            peripheral.discoverCharacteristics(nil, for: service)
        }
        log(debugMessage)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        var debugMessage = "Did discover characteristics for service '\(service.uuid)'\n"
        
        for characteristic in characteristics {
            
            /*
             The Properties value represents bit fields describing the permissions for the characteristic:
             Lower bits: 0000 - (Write, Write wo. response, Read, Broadcast)
             Upper bits: 0000 - (Extended Properties, Authenticated Signed Writes, Indicate, Notify)

             Common properties decimal values interpretations:
              2 = Read only         0000 0010
             10 = Read and write    0000 1010
             18 = Notify and read   0001 0010
             
             */
            
            // Provide log output for the discovered characteristic.
            var characteristicLogString = "Characteristic: \(characteristic.uuid), properties: \(characteristic.properties.rawValue) -"

            if characteristic.permissions.contains(.read) {
                characteristicLogString.append(" Read")
            }

            if characteristic.permissions.contains(.write) {
                characteristicLogString.append(" Write")
            }

            if characteristic.permissions.contains(.notify) {
                characteristicLogString.append(" Notify")
            }

            debugMessage += "  \(characteristicLogString)\n"
            log(debugMessage)
            
            if characteristic.uuid == CBUUID.DigitalToBoardCharacteristic {
                ledCharacteristic = characteristic
            }
            
            if characteristic.uuid == CBUUID.DigitalFromBoardCharacteristic {
                buttonCharacteristic = characteristic
            }
            
            if characteristic.uuid == CBUUID.AccelerationMeasurementCharacteristic {
                accelerationCharacteristic = characteristic
            }
            
            // Attempt to read the initial value for the discovered characteristic, if possible.
            if characteristic.permissions.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            
            // Add the characteristic to the pollCharacteristics array if it's one we want to poll for continously while connected to the peripheral.
            if pollCharacteristicIdentifiers.contains(characteristic.uuid) {
                pollCharacteristics.append(characteristic)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        if let error = error {
            let attError = CBATTError(_nsError: error as NSError)
            log("Error updating value for characteristic '\(characteristic.uuid)': Error code: \(attError.errorCode) - \(attError.localizedDescription)")
            return
        }
        
        switch characteristic.uuid {
        case CBUUID.TemperatureCharacteristic:
            if let temperature = DataParser.parseTemperature(data: characteristic.value) {
                Board.shared.temperature = temperature
            }
        case CBUUID.PressureCharacteristic:
            if let pressure = DataParser.parsePressure(data: characteristic.value) {
                Board.shared.pressure = pressure
            }
        case CBUUID.IlluminanceCharacteristic:
            if let illuminance = DataParser.parseIlluminance(data: characteristic.value) {
                Board.shared.ambientVisibleLight = illuminance
            }
        case CBUUID.AmbientIRCharacteristic:
            if let ambientInfraredLight = DataParser.parseAmbientIR(data: characteristic.value) {
                Board.shared.ambientInfraredLight = ambientInfraredLight
            }
        case CBUUID.LocationAndNavigationFeatureCharacteristic:
            // NOTE: Not saved to Board, only logged for debugging purposes.
            // See GATT Spec for LN Feature, section 3.127.
            log("Did read a value from LN Feature characteristic: \(characteristic.uuid), properties: \(characteristic.properties.rawValue), value: \(DataParser.valueDebugString(for: characteristic.value))")
        case CBUUID.LocationAndSpeedCharacteristic:
            if let location = DataParser.parseLocation(data: characteristic.value) {
                Board.shared.boardLocation.update(.located(latitude: location.latitude, longitude: location.longitude, elevation: location.elevation))
            }
        case CBUUID.BatteryLevelCharacteristic:
            if let batteryPercentage = DataParser.parseBatteryPercentage(data: characteristic.value) {
                Board.shared.batteryPercentage = batteryPercentage
            }
        case CBUUID.AccelerationMeasurementCharacteristic:
            if let acceleration = DataParser.parseAcceleration(data: characteristic.value) {
                Board.shared.xAcceleration = acceleration.x
                Board.shared.yAcceleration = acceleration.y
                Board.shared.zAcceleration = acceleration.z
            }
        case CBUUID.PowerSourceCharacteristic:
            if let isOnBattery = DataParser.parsePowerSource(data: characteristic.value) {
                Board.shared.isOnBattery = isOnBattery
            }
        case CBUUID.DebugLogCharacteristic:
            if let logMessage = DataParser.parseDebugLog(data: characteristic.value) {
                log(logMessage, source: .board)
            }
        case CBUUID.CellularSignalCharacteristic:
            if let cellSignalStrength = DataParser.parseCellularSignal(data: characteristic.value) {
                Board.shared.cellSignalStrength = cellSignalStrength
            }
        case CBUUID.CellularIMEICharacteristic:
            if let boardIMEI = DataParser.parseCellularIMEI(data: characteristic.value) {
                Board.shared.boardIMEI = boardIMEI
            }
        case CBUUID.WifiNameCharacteristic:
            if let wifiName = DataParser.parseWifiName(data: characteristic.value) {
                Board.shared.wifiName = wifiName
            }
        case CBUUID.WifiSignalCharacteristic:
            if let wifiSignalStrength = DataParser.parseWifiSignal(data: characteristic.value) {
                Board.shared.wifiSignalStrength = wifiSignalStrength
            }
        case CBUUID.DigitalToBoardCharacteristic:
            if let leds = DataParser.parseLed(data: characteristic.value) {
                Board.shared.redLedOn = leds.redLedOn
                Board.shared.greenLedOn = leds.greenLedOn
                Board.shared.blueLedOn = leds.blueLedOn
                Board.shared.whiteLedOn = leds.whiteLedOn
                Board.shared.buzzerOn = leds.buzzerOn
            }
        case CBUUID.DigitalFromBoardCharacteristic:
            if let buttonPressed = DataParser.parseButton(data: characteristic.value) {
                Board.shared.buttonPressed = buttonPressed
            }
        default:
            log("Did read a value from an unhandled characteristic: \(characteristic.uuid), properties: \(characteristic.properties.rawValue), value: \(DataParser.valueDebugString(for: characteristic.value))")
            break
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            log("Error writing value to '\(characteristic.uuid)': \(error.localizedDescription)")
            return
        }
        
        // Ask the peripheral about the current value for the written characteristic.
        connectedPeripheral?.readValue(for: characteristic)
    }
}

// This extension makes checking a characteristic's permissions cleaner and easier to read. It abstracts away the
// CBCharacterisProperties class and the raw value bitwise operator logic.
extension CBCharacteristic {

    enum CharacteristicPermissions {
        case read, write, notify
    }
    
    /// Returns a Set of permissions for the characteristic
    var permissions: Set<CharacteristicPermissions> {
        var permissionsSet = Set<CharacteristicPermissions>()

        if self.properties.rawValue & CBCharacteristicProperties.read.rawValue != 0 {
            permissionsSet.insert(CharacteristicPermissions.read)
        }

        if self.properties.rawValue & CBCharacteristicProperties.write.rawValue != 0 {
            permissionsSet.insert(CharacteristicPermissions.write)
        }

        if self.properties.rawValue & CBCharacteristicProperties.notify.rawValue != 0 {
            permissionsSet.insert(CharacteristicPermissions.notify)
        }

        return permissionsSet
    }
}
