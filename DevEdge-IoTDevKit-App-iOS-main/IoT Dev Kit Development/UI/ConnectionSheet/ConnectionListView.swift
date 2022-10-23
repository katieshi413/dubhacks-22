//
//  ConnectionListView.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 2/4/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

/// A view to show a list of available Bluetooth boards to connect to, as well as the currently connected board if a Bluetooth connection is active.
struct ConnectionListView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var bluetoothManager = Board.shared.bluetoothManager
    
    // The view's title depends on the current connection state.
    private var titleText: String {
        switch bluetoothManager.connectionState {
        case .connected:
            return "Connected to"
        case .connecting:
            return "Connecting"
        default:
            return "Not connected"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading){

                    HStack {
                        Text(titleText)
                            .font(.title)
                            .padding(.top, 18)
                            .padding(.bottom, 12)
                        
                        Spacer()
                    }

                    DisconnectButton(bluetoothManager: bluetoothManager)
                        .opacity(bluetoothManager.connectionState == .connected ? 1 : 0) // Hide button if no board is connected.
                    
                    HStack {
                        let listTitleText = bluetoothManager.detectedPeripherals.count > 0 ? "Select device" : "Searching for devices"

                        Text(listTitleText)
                            .font(.title)
                            .padding(.trailing, 16)

                        ProgressView()
                            .accessibilityLabel("Scanning in progress")
                    }
                    .padding(.top, 48)
                    
                    VStack(alignment: .leading) {
                        ForEach(bluetoothManager.detectedPeripherals, id: \.identifier) { peripheral in
                            Button {
                                bluetoothManager.attemptConnectionTo(peripheral)
                            } label: {
                                HStack(alignment: .firstTextBaseline) {
                                    Image("boardIconConnectSheet")
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        
                                        // Name and connection progress view
                                        Text(peripheral.name ?? "Unknown")
                                                .multilineTextAlignment(.leading)
                                        
                                        // Identifier
                                        BoardIdentifierView(identifier: peripheral.identifier.uuidString)
                                            .foregroundColor(.tmoGray60)
                                    }
                                    .padding(.trailing, 16)
                                    
                                    ProgressView()
                                        .opacity(peripheral.state == .connecting ? 1.0 : 0.0)

                                }
                                .padding(.vertical, 24)
                            }
                        }
                    }
                    .animation(.default , value: bluetoothManager.detectedPeripherals.count) // Animated transition of devices appearing in the list.

                    Spacer()
                }
                .foregroundColor(.tmoGray70)
                .padding(.horizontal, 24)
            }
        }
    }
    
    struct DisconnectButton: View {
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        
        @ObservedObject var bluetoothManager: BluetoothManager

        var body: some View {
            // Adapt layout to better fit content when using accessibility text sizes.
            let shouldLayoutVertically = dynamicTypeSize.isAccessibilitySize && horizontalSizeClass == UserInterfaceSizeClass.compact
            
            let buttonLabel = Group {
                HStack(alignment: .firstTextBaseline) {
                    Image("boardIconConnectSheet")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        
                        // Name and disconnect button
                        HStack {
                            Text(Board.shared.boardName)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            Text("Disconnect")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 2)
                                .overlay(
                                    Capsule()
                                        .stroke(lineWidth: 1)
                                )
                        }
                        
                        // Identifier
                        BoardIdentifierView(identifier: Board.shared.boardID?.uuidString ?? "-")
                    }
                }
            }
            
            Button {
                    bluetoothManager.disconnect()
            } label: {
                if shouldLayoutVertically {
                    VStack (alignment: .leading) {
                        buttonLabel
                    }
                } else {
                    buttonLabel
                }
            }
            .foregroundColor(.tmoMagenta)
            
        }
    }
    
    /// A view that presents a unique board identifier that makes it easier to pick the correct one from a list of boards.
    struct BoardIdentifierView: View {
        let identifier: String
        var body: some View {
            Text(identifier)
            .accessibilityLabel("Identifier \(String(identifier.suffix(4)))")
            .font(.caption)
            .lineLimit(1)
            .truncationMode(Text.TruncationMode.head)
        }
    }
}

struct ConnectionListView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionListView()
    }
}
