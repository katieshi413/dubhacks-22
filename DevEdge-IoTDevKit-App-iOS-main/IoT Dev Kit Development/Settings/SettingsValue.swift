//
//  SettingsManager.swift
//  IoT Dev Kit Development
//
//  Created by Daniel Lee on 2/15/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import Foundation



@propertyWrapper
struct SettingsValue<T> {
    private let key: String
    private let defaultValue: T
    
    
    init(key: String, default: T) {
        self.key = key
        self.defaultValue = `default`
    }
    
    var wrappedValue: T {
        get {
            
            guard let data = settingsBundle.value(forKey: key) as? T else {
                return defaultValue
            }
            return data
        }
    }
}

/**
 Read it once and save that in memory once when application wakes up.
 */
fileprivate let settingsBundle: UserDefaults = {
    let settingsBundleUserDefaults = UserDefaults()
    
    guard let settingsBundleURL = Bundle.main.url(forResource: "Settings", withExtension: "bundle"),
          let settingsData = try? Data(contentsOf: settingsBundleURL.appendingPathComponent("Root.plist")),
          let settingsPlist = try? PropertyListSerialization.propertyList(
            from: settingsData,
            options: [],
            format: nil) as? [String: Any],
          let settingsPreferences = settingsPlist["PreferenceSpecifiers"] as? [[String: Any]] else {
              return settingsBundleUserDefaults
          }
    
    var defaultsToRegister = [String: Any]()
    
    settingsPreferences.forEach { preference in
        if let key = preference["Key"] as? String {
            defaultsToRegister[key] = preference["DefaultValue"]
        }
    }
    
    settingsBundleUserDefaults.register(defaults: defaultsToRegister)
    return settingsBundleUserDefaults
}()
