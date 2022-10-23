//
//  FirstLaunchScreen.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 1/31/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

/// A view that gives the first time user some basic information about the app and prompts them to connect to a board via Bluetooth.
struct FirstLaunchScreen: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    Spacer(minLength: Constants.contentSpacing)
                    
                    Illustration()
                    
                    Spacer(minLength: Constants.contentSpacing)
                    
                    Text("Let’s create something amazing together")
                        .padding(.vertical, Constants.contentSpacing)
                        .font(.title)
                        .multilineTextAlignment(.center)
                    
                    Text("With this app, you can experiment with various sensors included in the kit.\n\nTo get started, let’s connect to your DevEdge Board over Bluetooth.")
                        .allowsTightening(true)
                        .multilineTextAlignment(.center)
                    
                    Spacer(minLength: Constants.buttonSpacing)
                    
                    ConnectButton()
                        .padding(.bottom, Constants.buttonSpacing)
                    
                    LaterButton()
                        .padding(.bottom, Constants.buttonSpacing)
                }
                .padding(.horizontal, Constants.contentSpacing)
                .foregroundColor(.tmoGray70)
                .frame(minHeight: geometry.size.height, maxHeight: .infinity)
            }
        }
    }
    
    struct Illustration: View {
        var body: some View {
            SceneModelView(manager: FirstLaunchSceneManager())
                .frame(minHeight: 120.0, maxHeight: 360.0)
                .aspectRatio(16.0/9.0, contentMode: .fit)
        }
    }
    
    struct ConnectButton: View {
        var body: some View {
            Button {
                Board.shared.bluetoothManager.initBluetooth()
            } label: {
                Image("firstLaunchBluetoothIcon")
                    .padding(.leading, 6)
                Text("Connect")
                    .padding(.trailing, 16)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .foregroundColor(.white)
            .accessibilityLabel("Connect Bluetooth")
        }
    }
    
    struct LaterButton: View {
        var body: some View {
            Button(role: ButtonRole.cancel) {
                AppController.shared.shouldShowFirstLaunchScreen = false
                AppController.shared.shouldShowDeviceSelectionSheet = false
            } label: {
                Text("Do it later")
            }
            .foregroundColor(.tmoMagenta)
        }
    }
}

// MARK: - Constants
private struct Constants {
    static var buttonSpacing: CGFloat = 24
    static var contentSpacing: CGFloat = 16
}

struct FirstLaunchScreen_Previews: PreviewProvider {
    static var previews: some View {
        FirstLaunchScreen()
        FirstLaunchScreen()
            .environment(\.sizeCategory, .accessibilityLarge)
            .previewDevice("iPod touch (7th generation)")
        FirstLaunchScreen()
            .previewDevice("iPhone 12 Pro Max")
    }
}
