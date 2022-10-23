//
//  AppContentScreen.swift
//  IoT Dev Kit Development
//
//  Created by Blake Bollinger on 11/15/21.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

/// The Tab view that is the parent of the different tabs in the view hierarchy.
struct AppContentScreen: View {
    @ObservedObject private var appController = AppController.shared
    @State private var selectedTab = 0
    
    var body: some View {
        
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tabItem {
                    Image(selectedTab == 0 ? "tabIconHomeFilled" : "tabIconHome")
                    Text("Home")
                }
                .tag(0)
            MotionScreen()
                .tabItem {
                    Image(selectedTab == 1 ? "tabIconMotionFilled" : "tabIconMotion")
                    Text("Motion")
                }
                .tag(1)
            LocationScreen()
                .tabItem {
                    Image(selectedTab == 2 ? "tabIconLocationFilled" : "tabIconLocation")
                    Text("Location")
                }
                .tag(2)
            DebugScreen()
                .tabItem {
                    Image(selectedTab == 3 ? "tabIconDebugFilled" : "tabIconDebug")
                    Text("Debug")
                }
                .tag(3)
            MoreScreen()
                .tabItem {
                    Image(selectedTab == 4 ? "tabIconMoreFilled" : "tabIconMore")
                    Text("More")
                }
                .tag(4)
        }
        .sheet(isPresented: $appController.shouldShowDeviceSelectionSheet,
               onDismiss: { appController.shouldShowDeviceSelectionSheet = false },
               content: { SheetView() })
    }
}

struct AppContentScreen_Previews: PreviewProvider {
    static var previews: some View {
        AppContentScreen()
    }
}
