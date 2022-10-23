//
//  DataParser.swift
//  Dev Kit
//
//  Created by Blake Bollinger on 7/21/21.
//  Copyright 2022 T-Mobile USA, Inc
//

import Foundation

struct DataParser {
    
    static func parseTemperature(data: Data?) -> Double? {
        guard let data = data else { return nil }

        // NOTE: Temperature is transmitted as a 2-byte value, we parse it into a signed 16-bit integer, Int16.
        
        if data.count < 2 { return nil }

        // Example for 23.30ºC
        // byte[0]: 26 = 00011010
        // byte[1]:  9 = 00001001
        // -> 00001001 00011010 = 2330 -> 23.30ºC
        
        let intValue = data.withUnsafeBytes { $0.load(as: Int16.self) }

        // Convert to Celsius. The sensor provides values as 100 * {Temperature in ºC}.
        let temperature = Double(intValue)/100.0
        
        log("Temperature is: " + String(temperature) + "°C, " + Self.valueDebugString(for: data))
        return temperature
    }
    
    static func parsePressure(data: Data?) -> Double? {
        guard let data = data else { return nil }
        
        // NOTE: Pressure is transmitted as a 4-byte value, we parse it into an unsigned 32-bit integer, UInt32.
        
        let intValue = data.withUnsafeBytes { $0.load(as: UInt32.self) }

        // Convert to `Millibar`. The sensor provides values as 1000 * {Pressure in Millibar}, a.k.a. 10 * {Pressure in Pascal}.
        let pressure = Double(intValue)/1000.0
        

        log("Pressure is: " + String(pressure) + " mbar")
        return pressure
    }
    
    static func parseIlluminance(data: Data?) -> Double? {
        guard var dataBytes = data else { return nil }
        let bytesCount = dataBytes.count
        
        // NOTE: Illuminance can be transmitted as a 3-byte (24 bits) value according to the GATT specification.
        if dataBytes.count >= 3 {
            
            // Since there is no 24 bit unsigned integer type we append a byte of zeroes and treat it as a UInt32.
            dataBytes.append(Data(count: 1))
            
            let intValue = dataBytes.withUnsafeBytes { $0.load(as: UInt32.self) }
            
            // Convert to Lux. The sensor provides values as 100 * {Light level in Lux}.
            let illuminance = Double(intValue)/100.0
            
            log("Visible light level is " + String(illuminance) + " lx, \(bytesCount) bytes. Data: " + Self.valueDebugString(for: data) )
            return illuminance
        }
        return nil
    }

    static func parseAmbientIR(data: Data?) -> Double? {
        guard let data = data else { return nil}
        let bytesCount = data.count
        
        // NOTE: Infrared light level is transmitted as a 2-byte (16 bits) value.
        if data.count >= 2 {
            
            let intValue = data.withUnsafeBytes { $0.load(as: UInt16.self) }
            
            // Convert to W/m2. The sensor provides values as 10 * {IR level in W/m2}.
            let ambientIR = Double(intValue)/10.0
            
            log("Infrared light level is " + String(ambientIR) + ", \(bytesCount) bytes. Data: " + Self.valueDebugString(for: data) )
            return ambientIR
        }
        return nil
    }
    
    static func parseBatteryPercentage(data: Data?) -> Int? {
        guard let data = data else { return nil }
        
        let intValue = data.withUnsafeBytes { $0.load(as: UInt8.self) }
        log("Battery level is " + String(intValue) + "%")
        return Int(intValue)
    }
        
    static func parseAcceleration(data: Data?) -> (x: Float, y: Float, z: Float)? {
        guard let data = data else { return nil }

        if data.count >= 6 {
            var xValueTimes100: Int16 = 0
            var yValueTimes100: Int16 = 0
            var zValueTimes100: Int16 = 0
            (data as NSData).getBytes(&xValueTimes100, range: NSMakeRange(0, 2))
            (data as NSData).getBytes(&yValueTimes100, range: NSMakeRange(2, 2))
            (data as NSData).getBytes(&zValueTimes100, range: NSMakeRange(4, 2))
            let xValue = Float(xValueTimes100) / 100.0
            let yValue = Float(yValueTimes100) / 100.0
            let zValue = Float(zValueTimes100) / 100.0
            
            return (xValue, yValue, zValue)
        }
        
        return nil
    }
    
    static func parseLocation(data: Data?) -> (latitude: Double, longitude: Double, elevation: Double?)? {
        guard let data = data else { return nil }
        
        // There needs to be at least 10 bytes of data for the location to exist.
        // 2 bytes of flag values, plus 4 bytes of longitude and 4 bytes of latitude data.
        if data.count >= 10 {
            
            // Print out the bytes for debug purposes
            var debugMessage = "Location data: " + Self.valueDebugString(for: data)

            var flagValue: UInt16 = 0
            var latitudeValue: Int32 = 0
            var longitudeValue: Int32 = 0
            var elevationValue: Int32 = 0
            
            // Parse the flag value.
            (data as NSData).getBytes(&flagValue, range: NSMakeRange(0, 2))  // Bytes 0 and 1 are flags
            let originalFlagValue = flagValue

            /*
             Parse the flag value here to find out if location data is present, and which bytes to read it from.
             The flag value in the first two bytes is defined in the GATT Specification, see section 3.129 "Location
             And Speed" for information about the data structure and flags.
             00100000 10001100
             Exampel flag value: 132
             00000000 10000100
                    \ /   |||\
                     |    ||\ Instantaneous Speed Present
                     |    |\ Distance Present
                     |    \ Location Present
                     |     Elevation Present
                     Position Status (0=No Position, 1=Position Ok, 2=Estimated Position, 3=Last Known Position)

             We need to skip past 2 bytes if flag 0 (Speed) is set and 3 bytes if flag 1 (Distance) is set before
             we parse the fields for 'Location - Latitude' and 'Location - Longitude'.
             If flag 3 is set we also parse the field for 'Elevation'.
             */
            
            var coordinateStartByte = 2 // We expect the location coordinates to follow immediately after the 2 flag bytes.
            
            let speedPresent        = flagValue & 0b0000000000000001 > 0
            let distancePresent     = flagValue & 0b0000000000000010 > 0
            let locationPresent     = flagValue & 0b0000000000000100 > 0
            let elevationPresent    = flagValue & 0b0000000000001000 > 0
            
            if !locationPresent {
                // Early exit because the flags indicate no location value is present in the data.
                debugMessage += " \nFlags: \(originalFlagValue) - - \(String(originalFlagValue, radix: 2))"
                log(debugMessage)
                return nil
            }
            
            coordinateStartByte += speedPresent ? 2 : 0     // Skip 2 bytes of speed data, if present.
            coordinateStartByte += distancePresent ? 3 : 0  // Skip 3 bytes of distance data, if present.
            
            // Parse the latitude and longitude coordinates.
            (data as NSData).getBytes(&latitudeValue, range: NSMakeRange(coordinateStartByte, 4))  // 4 bytes for latitude.
            (data as NSData).getBytes(&longitudeValue, range: NSMakeRange(coordinateStartByte + 4, 4)) // 4 bytes for longitude.
            
            let latitude = Double(latitudeValue)/10000000
            let longitude = Double(longitudeValue)/10000000
            
            var elevation: Double? = nil
            if elevationPresent {
                // Parse the elevation. The board provides it as 100 * { Elevation in meters }.
                
                let elevationStartByte = coordinateStartByte + 8 //
                
                (data as NSData).getBytes(&elevationValue, range: NSMakeRange(elevationStartByte, 3))  // 3 bytes for elevation.
                elevation = Double(elevationValue)/100
            }
            
            let elevationDebugMessage = elevation == nil ? "n/a" : String(elevation!)
            debugMessage += " \nLat: \(latitude), Long: \(longitude), Elevation: \(elevationDebugMessage), Flags: \(originalFlagValue) - - \(String(originalFlagValue, radix: 2))"
            log(debugMessage)
            
            return (latitude, longitude, elevation)
        }
        
        return nil
    }
    
    /// Parses the data as a power source to determine if the board is powered by battery.
    /// - returns: `true` if running on battery power, or `false` if plugged into external power.
    static func parsePowerSource(data: Data?) -> Bool? {
        guard let data = data else { return nil }
        
        let intValue = data.withUnsafeBytes { $0.load(as: UInt8.self) }
        let usingBattery = intValue == 1
        log("Power source is: \(usingBattery ? "Battery" : "Plugged in")")
        return usingBattery
    }
    
    static func parseDebugLog(data: Data?) -> String? {
        guard let data = data else { return nil }
        
        // Since ASCII is a subset of UTF-8 this will still work if the string is ASCII-encoded.
        guard let logMessage = data.parseAsNullTerminatedString(encoding: .utf8) else { return nil }
        
        return logMessage
    }
    
    static func parseCellularSignal(data: Data?) -> Int? {
        guard let data = data else { return nil }
        
        let intValue = data.withUnsafeBytes { $0.load(as: Int8.self) }
        log("Cellular signal: " + String(intValue) + " dBm")
        return Int(intValue)
    }

    static func parseCellularIMEI(data: Data?) -> String? {
        guard let data = data else { return nil }
        
        let intValue = data.withUnsafeBytes { $0.load(as: UInt64.self) }
        log("Cellular IMEI: " + String(intValue))
        return String(intValue)
    }
    
    static func parseWifiName(data: Data?) -> String? {
        guard let data = data else { return nil }

        // Since ASCII is a subset of UTF-8 this will still work if the string is ASCII-encoded.
        var wifiName = data.parseAsNullTerminatedString(encoding: .utf8)
        
        // Interpret an empty string as the Wi-Fi network name not being available.
        if let wifiNameString = wifiName {
            wifiName = wifiNameString.isEmpty ? nil : wifiNameString
        }
        
        log("Wi-fi name: '" + (wifiName ?? "n/a") + "'")
        return wifiName
    }
    
    static func parseWifiSignal(data: Data?) -> Int? {
        guard let data = data else { return nil }
        
        let intValue = data.withUnsafeBytes { $0.load(as: Int8.self) }
        log("Wi-fi signal: " + String(intValue) + " dBM")
        return Int(intValue)
    }
    
    static func parseLed(data: Data?) -> (redLedOn: Bool, greenLedOn: Bool, blueLedOn: Bool, whiteLedOn: Bool, buzzerOn: Bool)? {
        guard let data = data else { return nil }

        // LED and audio buzzer state:
        //  0 - All off:                    0000 0000
        //  1 - RGB led, only R turned on   0000 0001
        //  2 - RGB led, only G turned on   0000 0010
        //  4 - RGB led, only B turned on   0000 0100
        //  8 - WHITE led turned on         0000 1000
        // 15 - All LEDs turned on          0000 1111
        // 16 - Buzzer active, all LEDs off 0001 0000
        
        var intValue = data.withUnsafeBytes { $0.load(as: UInt8.self) }
        log("LED and audio buzzer state: " + String(intValue))
        
        let bitmask: UInt8  = 0b00000001
        let redLedOn = intValue & bitmask > 0
        
        intValue = intValue >> 1 // Right shift to move the next relevant bit to the first position.
        let greenLedOn = intValue & bitmask > 0
        
        intValue = intValue >> 1 // Right shift to move the next relevant bit to the first position.
        let blueLedOn = intValue & bitmask > 0
        
        intValue = intValue >> 1 // Right shift to move the next relevant bit to the first position.
        let whiteLedOn = intValue & bitmask > 0

        intValue = intValue >> 1 // Right shift to move the next relevant bit to the first position.
        let buzzerOn = intValue & bitmask > 0
        
        return (redLedOn, greenLedOn, blueLedOn, whiteLedOn, buzzerOn)
    }
    
    /// Parses the data to determine whether the button on the board is being pressed or not.
    /// - returns: `true` if the button is in the pressed state, or `false` it is not pressed.
    static func parseButton(data: Data?) -> Bool? {
        guard let data = data else { return nil }

        // The value will be 1 or 0, a.k.a. true or false.
        let intValue = data.withUnsafeBytes { $0.load(as: UInt8.self) }
        log("Button state: " + String(intValue))
        return intValue == 1
    }
    
    /// Returns a `String` describing the bytes in the given `data` for debugging purposes.
    static func valueDebugString(for data: Data?) -> String {
        guard let data = data else { return "nil" }
        
        // Print out the bytes for debug purposes
        let bytesPointer = (data as NSData).bytes
        var debugMessage = "\(data.count) bytes\n"
        
        let byteSeparator = ", "
        
        // These are the data bytes.
        for i in 0..<data.count {
            let offsetPointer = bytesPointer + i
            
            let intValue = offsetPointer.load(as: UInt8.self)
            debugMessage += "[\(i)]: \(intValue)\(byteSeparator)"
        }
        
        if debugMessage.hasSuffix(byteSeparator) {
            debugMessage.removeLast(byteSeparator.count)
        }
        
        return debugMessage
    }
}
