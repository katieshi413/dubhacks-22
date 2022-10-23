//
//  LedStateIndicatorView.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 9/14/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

enum LedType {
    case white
    case rgb
}

/// A view with images and labels to indicate the current state of the LEDs on a connected Bluetooth device. It shows the state for both the RGB and White LEDs.
struct LedStateIndicatorView: View {

    @ObservedObject var connectedBoard: Board

    let symbolFontSize: CGFloat = 20
    let symbolMinFrameDimension: CGFloat = 28
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            LedStateIndicatorSymbolView(ledType: .rgb, connectedBoard: connectedBoard)
                .font(Font.system(size: symbolFontSize))
                .frame(minWidth: symbolMinFrameDimension, minHeight: symbolMinFrameDimension)
            
            Text(rgbTitle)
                .padding(.trailing, 4)
            
            LedStateIndicatorSymbolView(ledType: .white, connectedBoard: connectedBoard)
                .font(Font.system(size: symbolFontSize))
                .frame(minWidth: symbolMinFrameDimension, minHeight: symbolMinFrameDimension)
            
            Text("W")
        }
            .font(.subheadline)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }
    
    /// Returns "RGB" if all three are off or all three are on, otherwise "R", "G", "B", "R/G", "R/B" or "G/B" depending on which LEDs are turned on.
    var rgbTitle: String {
        let red = connectedBoard.redLedOn
        let green = connectedBoard.greenLedOn
        let blue = connectedBoard.blueLedOn
        
        if (red && green && blue) || (!red && !green && !blue) { return "RGB" }
        if red && green { return "R/G" }
        if red && blue { return "R/B" }
        if green && blue { return "G/B" }
        if red { return "R" }
        if green { return "G" }
        if blue { return "B" }
        
        return "-"
    }
}

/// An illustration symbol for the state of the connected Bluetooth board's LED of the given `ledType`.
struct LedStateIndicatorSymbolView: View {
    @Environment(\.colorScheme) var colorScheme
    let ledType: LedType
    @ObservedObject var connectedBoard: Board
    
    var body: some View {
        return ledType == .rgb ? AnyView( rgbIndicatorSymbol ) : AnyView( whiteIndicatorSymbol )
    }
    
    private var whiteIndicatorSymbol: some View {
        var symbol = Image("custom.circle.small")
        if connectedBoard.whiteLedOn {
            symbol = colorScheme == .light ? Image(systemName:"sun.max") : Image(systemName:"sun.max.fill")
        }
        return symbol
    }
    
    private var rgbIndicatorSymbol: some View {
        let red = connectedBoard.redLedOn
        let green = connectedBoard.greenLedOn
        let blue = connectedBoard.blueLedOn
        let lit = red || green || blue
        
        var symbol = lit ? Image(systemName: "sun.max.fill") : Image("custom.circle.small")

        if red && green && blue {
            // Aadapt the symbol for light/dark mode.
            symbol = colorScheme == .light ? Image(systemName: "sun.max") : Image(systemName: "sun.max.fill")
        }
        
        let color = rgbIndicatorColor(red: red, green: green, blue: blue)
        return color == nil ? AnyView( symbol ) : AnyView( symbol.foregroundColor(color) )
    }
    
    private func rgbIndicatorColor(red: Bool, green: Bool, blue: Bool) -> Color? {
        var color: Color?
        if red && green && blue { /* Keep the primary color */ }
        else if red && green { color = Color.ledRG }
        else if red && blue { color = Color.ledRB }
        else if green && blue { color = Color.ledGB }
        else if red { color = Color.ledR }
        else if green { color = Color.ledG }
        else if blue { color = Color.ledB }
        return color
    }
}

struct LedStateIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        LedStateIndicatorSymbolView(ledType: .rgb, connectedBoard: Board.shared)
        LedStateIndicatorSymbolView(ledType: .white, connectedBoard: Board.shared)
    }
}
