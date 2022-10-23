//
//  IoT_Dev_Kit_DevelopmentApp.swift
//  IoT Dev Kit Development
//
//  Created by Blake Bollinger on 11/15/21.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

/// This is the entry point for the app.
/// It redirects the user to either the `FirstLaunchScreen` or the `AppContentScreen` depending on a property in `AppController`.
@main
struct IoT_Dev_Kit_DevelopmentApp: App {
    @ObservedObject private var appController = AppController.shared
        
    var body: some Scene {
        WindowGroup {
            
            Group {
                if appController.shouldShowFirstLaunchScreen {
                    FirstLaunchScreen().transition(.opacity) // First launch instructions screen.
                } else {
                    AppContentScreen()  // The normal app screen.
                }
            }
            .animation(.default, value: appController.shouldShowFirstLaunchScreen) // Animated screen transition.
            
        }
    }
}
