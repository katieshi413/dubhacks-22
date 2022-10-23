//
//  SheetView.swift
//  IoT Dev Kit Development
//
//  Created by Geol Kim on 12/20/21.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

// This connection sheet parent view shows the appropriate sheet content view depending on the app's Bluetooth state.
struct SheetView: View {
    
    private enum SheetContent {
        case instructions
        case bluetoothWarning
        case devicesList
    }

    @Environment(\.dismiss) var dismiss
    @ObservedObject private var bluetoothManager = Board.shared.bluetoothManager
    @State private var avoidInstructions: Bool = false

    // A property that defines which content should be shown in the sheet based on the current app state.
    private var contentToShow: SheetContent {
        if !bluetoothManager.isBluetoothAvailable { return .bluetoothWarning }
        else if (avoidInstructions || bluetoothManager.connectionState == .connected || bluetoothManager.detectedPeripherals.count > 0) { return .devicesList}
        else { return .instructions }
    }
    
    var body: some View {
        VStack{
            HStack {
                Spacer()
                Capsule()
                    .foregroundColor(.tmoGray40)
                    .frame(width: 36.0, height: 5.0)
                    .padding(.top, 5)
                    .padding(.bottom, 34)
                Spacer()
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15).weight(.bold))
                        .frame(width: 30, height: 30)
                        .accentColor(.tmoGray60)
                        .background(Color.tmoGray30)
                        .clipShape(Circle())
                }
                .padding(13)
                .accessibilityLabel("Close")
            }
            
            Group {
                switch contentToShow {
                case .instructions:
                    InstructionView()
                case .bluetoothWarning:
                    TurnOnBluetoothView()
                case .devicesList:
                    ConnectionListView()
                        .onAppear {
                            // Once the list has been shown the user no longer needs to see the instructions.
                            // NOTE: This avoids a quick flash of the instructions view after the user disconnects from their board, which otherwise may occur because it takes a few seconds for the disconnected board to again appear in the list of detected boards.
                            avoidInstructions = true
                        }
                }
            }
            .frame( maxWidth: .infinity, maxHeight: .infinity )
        }
        .onAppear { // Start Bluetooth scanning.
            bluetoothManager.startScanning()
        }
        .onDisappear { // Stop Bluetooth scanning.
            bluetoothManager.stopScanning()
        }
        .animation(.default, value: contentToShow) // Animated screen transition.
    }
}
    
struct Sheet_Previews: PreviewProvider {
    static var previews: some View {
        SheetView()
            .environment(\.sizeCategory, .extraSmall)
    }
}
