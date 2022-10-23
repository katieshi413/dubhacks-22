//
//  LoggerTests.swift
//  IoT Dev Kit DevelopmentTests
//
//  Created by Ahlberg, Kim on 7/7/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import XCTest

class LoggerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Logger.shared.removeAllLoggedEvents()
        Logger.shared.maximumLoggedEventsCount = 100
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLogAppEvent() throws {
        let message = "App event message"
        log(message, source: .app)
        
        let loggedEvent = Logger.shared.loggedEvents.first
        XCTAssertEqual(loggedEvent?.message, message)
        XCTAssertEqual(loggedEvent?.context, Logger.LoggingSource.app)
    }
    
    func testLogBoardEvent() throws {
        let message = "Board event message"
        log(message, source: .board)
        
        let loggedEvent = Logger.shared.loggedEvents.first
        XCTAssertEqual(loggedEvent?.message, message)
        XCTAssertEqual(loggedEvent?.context, Logger.LoggingSource.board)
    }
    
    func testLogAppEventByDefault() throws {
        let message = "My app event message"
        log(message) // No source provided, expected to use .app by default.
        
        let loggedEvent = Logger.shared.loggedEvents.first
        XCTAssertEqual(loggedEvent?.message, message)
        XCTAssertEqual(loggedEvent?.context, Logger.LoggingSource.app)
    }
    
    func testRemoveAllLoggedEvents() throws {
        for i in 1...Logger.shared.maximumLoggedEventsCount {
            let message = "\(i)"
            log(message)
        }

        Logger.shared.removeAllLoggedEvents()
        let expected = 0
        let numberOfEvents = Logger.shared.loggedEvents.count
        
        XCTAssertEqual(numberOfEvents, expected)
    }
    
    func testPurgesOldestEventWhenMaximumLoggedEventsCountExceeded() throws {
        for i in 1...Logger.shared.maximumLoggedEventsCount {
            let message = "\(i)"
            log(message)
        }
        XCTAssertEqual(Logger.shared.loggedEvents.count, Logger.shared.maximumLoggedEventsCount)
        
        let mostRecentLoggedEvent = Logger.shared.loggedEvents.first
        XCTAssertEqual(mostRecentLoggedEvent?.message, "\(Logger.shared.maximumLoggedEventsCount)")

        var oldestLoggedEvent = Logger.shared.loggedEvents.last
        XCTAssertEqual(oldestLoggedEvent?.message, "1")
        
        // Logging one more event should purge the oldest logged event to make room for the new one.
        log("Event that should trigger purge of oldest event")
        XCTAssertEqual(Logger.shared.loggedEvents.count, Logger.shared.maximumLoggedEventsCount)
        
        oldestLoggedEvent = Logger.shared.loggedEvents.last
        XCTAssertEqual(oldestLoggedEvent?.message, "2")
    }

    func testSettingMaximumLoggedEventsCountPurgesAdditionalEvents() throws {
        for i in 1...Logger.shared.maximumLoggedEventsCount {
            let message = "\(i)"
            log(message)
        }
        XCTAssertEqual(Logger.shared.loggedEvents.count, Logger.shared.maximumLoggedEventsCount)
        let newestEventMessage = Logger.shared.loggedEvents.first!.message
        
        let newLimit = Logger.shared.maximumLoggedEventsCount / 2
        
        // Updating the Logger's limit should purge old events to fit only the new maximum number.
        Logger.shared.maximumLoggedEventsCount = newLimit
        XCTAssertEqual(Logger.shared.loggedEvents.count, newLimit)
        
        // The newest event should not have been purged.
        XCTAssertEqual(Logger.shared.loggedEvents.first?.message, newestEventMessage)
    }
}
