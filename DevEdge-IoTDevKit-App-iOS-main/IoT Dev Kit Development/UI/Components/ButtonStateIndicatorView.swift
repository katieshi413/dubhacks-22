//
//  ButtonStateIndicatorView.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 9/15/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

/// A view with an image and a label to indicate the current state of the of the button on a connected Bluetooth device. The button can either be "Pressed" or "Not pressed". If a board is not connected, that is indicated by a dash.
struct ButtonStateIndicatorView: View {
    @ObservedObject var connectedBoard: Board
    
    private let symbolFontSize: CGFloat = 20
    private let symbolMinFrameDimension: CGFloat = 28
    private var buttonTitle: String {
        if !connectedBoard.isConnected { return "-" }
        return connectedBoard.buttonPressed ? "Pressed" : "Not pressed" }
    private var buttonImageName: String {
        return (connectedBoard.isConnected && connectedBoard.buttonPressed) ? "hand.tap.fill" : "hand.point.up.left"
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName:buttonImageName)
                .foregroundColor(Color.tmoMagenta)
                .font(Font.system(size: symbolFontSize))
                .frame(minWidth: symbolMinFrameDimension, minHeight: symbolMinFrameDimension)
            
            Text( buttonTitle.uppercased() )
                .font(.subheadline)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .allowsTightening(true)
        }
    }
}

struct ButtonStateIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonStateIndicatorView(connectedBoard: Board.shared)
    }
}
