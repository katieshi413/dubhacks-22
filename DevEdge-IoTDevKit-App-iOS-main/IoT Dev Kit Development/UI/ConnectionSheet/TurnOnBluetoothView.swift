//
//  TurnOnBluetoothView.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 2/4/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

/// A view instructing the user to turn on Bluetooth in the system Settings app.
struct TurnOnBluetoothView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .center){
                    
                    // Adapt layout to better fit content when using accessibility text sizes.
                    let horizontalTextPadding : CGFloat = dynamicTypeSize.isAccessibilitySize ? 8 : 40
                    
                    HStack {
                        Spacer()
                        Text("Turn Bluetooth On")
                            .font(.title)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.top, 18)

                    Image("bluetoothError")
                        .padding(.vertical, 48)
                    
                    Text("Go to System Settings to turn on Bluetooth, so the app can detect and find your DevEdge Board.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, horizontalTextPadding)
                    
                    Button {
                        AppController.shared.openSettingsApp()
                    } label: {
                        Text("Open Settings")
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .foregroundColor(.white)
                    .padding(24)
                    
                    Spacer()
                }
                .foregroundColor(.tmoGray70)
            }
        }
    }
}

struct TurnOnBluetoothView_Previews: PreviewProvider {
    static var previews: some View {
        TurnOnBluetoothView()
    }
}
