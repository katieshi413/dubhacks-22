//
//  CBUUID.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 6/30/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import Foundation
import CoreBluetooth

/// An extension providing a subset of identifiers used for Bluetooth low energy communication, as defined in the Bluetooth 16-bit UUID Numbers Document.
extension CBUUID {
    //MARK:- Service identifiers
    
    /// Automation I/O (org.bluetooth.service.automation_io).
    static let AutomationIO = CBUUID(string: "0x1815")
    
    /// Battery Information Service (org.bluetooth.service.battery_service).
    static let BatteryService = CBUUID(string: "0x180F")
    
    /// Environmental Sensing (org.bluetooth.service.environmental_sensing).
    static let EnvironmentalSensingService = CBUUID(string: "0x181A")
    
    /// Location and Navigation (org.bluetooth.service.location_and_navigation).
    static let LocationAndNavigationService = CBUUID(string: "0x1819")

    // MARK: - Characteristic identifiers
    
    //
    // Battery characteristics
    //
    
    /// Battery Level Characteristic (org.bluetooth.characteristic.battery_level).
    static let BatteryLevelCharacteristic = CBUUID(string: "0x2A19")
    
    //
    // Environmental Sensing characteristics
    //
    
    /// Pressure (org.bluetooth.characteristic.pressure).
    static let PressureCharacteristic = CBUUID(string: "0x2A6D")
    
    ///  Temperature (org.bluetooth.characteristic.temperature).
    static let TemperatureCharacteristic = CBUUID(string: "0x2A6E")
    
    /// Illuminance (org.bluetooth.characteristic.illuminance).
    static let IlluminanceCharacteristic = CBUUID(string: "0x2AFB")
    
    //
    // Location and Navigation characteristics
    //
    
    /// Location and Navigation Feature (org.bluetooth.characteristic.ln_feature).
    static let LocationAndNavigationFeatureCharacteristic = CBUUID(string: "0x2A6A")
    
    /// Location and Speed (org.bluetooth.characteristic.location_and_speed).
    static let LocationAndSpeedCharacteristic = CBUUID(string: "0x2A67")
}

/// An extension providing custom identifiers used by the T-Mobile DevEdge Dev Kit.
extension CBUUID {
    // MARK: - Service identifiers
    
    /// Cellular information service, provides information on the DevEdge board's cellular network status.
    static let CellularService = CBUUID(string: "0x2618484C-7465-441D-BC3F-35F1AF1C6F16")
    
    /// Debug log service, provides log output from the DevEdge board.
    static let DebugService = CBUUID(string: "0xEB8AEA80-88A7-42E4-BB93-68421259CDFE")
    
    /// Inertial Measurement (e.g. Acceleration and Orientation).
    static let InertialMeasurementService = CBUUID(string: "0xA4E649F4-4BE5-11E5-885D-FEFF819CDC9F")
    
    /// Power Source.
    static let PowerSourceService = CBUUID(string: "0xEC61A454-ED00-A5E8-B8F9-DE9EC026EC51")

    /// Wi-fi information service, provides information on the DevEdge board's Wi-fi network status.
    static let WifiService = CBUUID(string: "0x75C7E8DF-376A-4171-A096-41D486BB3D72")
    
    // MARK: - Characteristic identifiers

    //
    // Automation I/O characteristics
    //

    /// Digital (org.bluetooth.characteristic.digital).
    static let DigitalToBoardCharacteristic =   CBUUID(string: "0x2A56")
    static let DigitalFromBoardCharacteristic = CBUUID(string: "0x2A57")

    //
    // Environmental Sensing characteristics
    //
    
    /// Ambient Infrared Light (custom).
    static let AmbientIRCharacteristic = CBUUID(string: "0xEEDC804D-AF50-4488-942E-B4E9043F1687")
    
    //
    // Inertial Measurement characteristics
    //
    
    /// Acceleration Measurement (custom).
    static let AccelerationMeasurementCharacteristic = CBUUID(string: "0xC4C1F6E2-4BE5-11E5-885D-FEFF819CDC9F")
    
    //
    // Power Source characteristics
    //
    
    /// Power source.
    static let PowerSourceCharacteristic = CBUUID(string: "0xEC61A454-ED01-A5E8-88F9-DE9EC026EC51")

    //
    // Debug Log characteristics
    //
 
    /// Debug log output as ASCII encoded strings.
    static let DebugLogCharacteristic = CBUUID(string: "0xD3BEC995-37F9-4FEE-97C0-6F494A95530D")
    
    //
    // Cellular Network characteristics
    //

    /// The cellular signal strength as an 8 bit signed Int.
    /// Reported in dBm so we expect negative numbers. The closer to 0 the number is, the better the signal.
    /// A value of exactly 0 means disconnected.
    static let CellularSignalCharacteristic = CBUUID(string: "0xE3B403A4-E97D-4401-8D09-87B6AF705298")
    
    /// The cellular IMEI number as a 64 bit unsigned Int.
    static let CellularIMEICharacteristic = CBUUID(string: "0x02D93BC0-46DA-4444-9527-A063F082023B")
    
    //
    // Wi-Fi Network characteristics
    //
    
    /// The name of the connected Wi-Fi network as an ASCII encoded, Null terminated string.
    /// NOTE: From the IEEE 802.11 specification: "The length of the SSID field is between 0 and 32 octets. [...] the character encoding of the octets in this SSID element is unspecified."
    /// The specification also mentions a special “UTF-8 SSID subfield.”  This is a flag used to tell clients interested in this network decode the bytes in the SSID field as if they were encoded using UTF-8. Many access points do not take advantage of this flag even if they do encode their SSIDs using UTF-8 encoding.
    static let WifiNameCharacteristic = CBUUID(string: "0x2618484D-7465-BC3F-B8F9-35F1AF1C6F16")
    
    /// The Wi-fi signal strength as an 8 bit signed Int.
    /// Reported in dBm so we expect negative numbers. The closer to 0 the number is, the better the signal.
    /// A value of exactly 0 means disconnected.
    static let WifiSignalCharacteristic = CBUUID(string: "0x5ED074FA-7205-4395-A95C-2223928BDC64")
}
