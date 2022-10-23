//
//  DataParserTests.swift
//  IoT Dev Kit DevelopmentTests
//
//  Created by Ahlberg, Kim on 7/6/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import XCTest

class DataParserTests: XCTestCase {

    //
    // MARK: - Setup and teardown
    //
    
    override func setUpWithError() throws {
        // NOTE: We don't need any setup code because the parser functions are self contained.
    }

    override func tearDownWithError() throws {
        // NOTE: We don't need any teardown code because the parser functions are self contained and there is no state to reset.
    }

    //
    // MARK: - Sensor parsing tests
    //
    
    // MARK: Temperature
    
    /// Test to verify the parser returns `nil` if supplied with `nil` data.
    func testTemperatureInvalidDataNil() throws {
        let returnedValue = DataParser.parseTemperature(data: nil )
        XCTAssertNil(returnedValue)
    }

    /// Test to verify the parser returns `nil` if supplied with empty data.
    func testTemperatureInvalidDataEmpty() throws {
        let data = Data()
        let returnedValue = DataParser.parseTemperature(data: data )
        XCTAssertNil(returnedValue)
    }

    /// Test to verify the parser returns `nil` if not supplied with enough data.
    func testTemperatureInvalidDataOneByte() throws {
        let bytes: [UInt8] = [0b0000000]

        let data = NSData(bytes: bytes, length: bytes.count) as Data
        let returnedValue = DataParser.parseTemperature(data: data )
        XCTAssertNil(returnedValue)
    }

    /// Test to verify the parser returns the exact value expected for the temperature zero ºC.
    func testTemperatureValidDataZero() throws {
        let bytes: [UInt8] = [0b0000000, 0b0000000]
        let expected: Double = 0.0

        let data = NSData(bytes: bytes, length: bytes.count) as Data
        let returnedValue = DataParser.parseTemperature(data: data )
        XCTAssertEqual(returnedValue, expected)
    }

    /// Test to verify the parser returns the exact value expected for a positive temperature.
    func testTemperatureValidDataPositive() throws {
        let bytes: [UInt8] = [0b00011010, 0b00001001]
        let expected: Double = 23.30

        let data = NSData(bytes: bytes, length: bytes.count) as Data
        let returnedValue = DataParser.parseTemperature(data: data )
        XCTAssertEqual(returnedValue, expected)
    }

    /// Test to verify the parser returns the exact value expected for a positive temperature.
    func testTemperatureValidDataPositive2() throws {
        let bytes: [UInt8] = [0b00001100, 0b00000100]
        let expected: Double = 10.36

        let data = NSData(bytes: bytes, length: bytes.count) as Data
        let returnedValue = DataParser.parseTemperature(data: data )
        XCTAssertEqual(returnedValue, expected)
    }

    /// Test to verify the temperature parser can handle negative temperature values.
    func testTemperatureValidDataNegative() throws {
        let bytes: [UInt8] = [0b01000110, 0b11111000]
        let expected: Double = -19.78

        let data = NSData(bytes: bytes, length: bytes.count) as Data
        let returnedValue = DataParser.parseTemperature(data: data )
        XCTAssertEqual(returnedValue, expected)
    }
    
    /// Test to verify the temperature parser provides a value based on only the two first bytes in the data.
    func testTemperatureValidDataWithExtraBytes() throws {
        // Set up two byte arrays where the first two bytes are identical and match the expected value, but additional bytes differ between the two arrays.
        let bytes1: [UInt8] = [0b01011111, 0b00000111, 0b10001000]
        let bytes2: [UInt8] = [0b01011111, 0b00000111, 0b11101000, 0b10001101]
        let expected: Double = 18.87

        let data1 = NSData(bytes: bytes1, length: bytes1.count) as Data
        let returnedValue1 = DataParser.parseTemperature(data: data1 )
        
        let data2 = NSData(bytes: bytes2, length: bytes2.count) as Data
        let returnedValue2 = DataParser.parseTemperature(data: data2 )

        // Assert that the two returned values are equal, and that both match the expected value.
        XCTAssertEqual(returnedValue1, returnedValue2)
        XCTAssertEqual(returnedValue1, expected)
        XCTAssertEqual(returnedValue2, expected)
    }
    
    func testLocationWithoutElevation() throws {
        let bytes: [UInt8] = [132, 0,               // Flags
                              186, 50, 96, 28,      // Latitude
                              198, 137, 21, 183]    // Longitude
        let data = NSData(bytes: bytes, length: bytes.count) as Data
        let returnedValue = DataParser.parseLocation(data: data)
        
        XCTAssertNotNil(returnedValue)
        XCTAssertNil(returnedValue?.elevation)
        XCTAssertEqual(returnedValue?.latitude, 47.606649)
        XCTAssertEqual(returnedValue?.longitude, -122.3325242)
    }
    
    func testLocationWithElevation() throws {
        let bytes: [UInt8] = [140, 0,               // Flags
                              186, 50, 96, 28,      // Latitude
                              198, 137, 21, 183,    // Longitude
                              42, 4, 0]             // Elevation
        let data = NSData(bytes: bytes, length: bytes.count) as Data
        let returnedValue = DataParser.parseLocation(data: data)
        
        XCTAssertNotNil(returnedValue)
        XCTAssertNotNil(returnedValue?.elevation)
        XCTAssertEqual(returnedValue?.latitude, 47.606649)
        XCTAssertEqual(returnedValue?.longitude, -122.3325242)
        XCTAssertEqual(returnedValue?.elevation, Double(10.66))
    }
    
    // MARK: Pressure
    
    // TODO: Add testing for the air pressure sensor and other sensors and readings.
}
