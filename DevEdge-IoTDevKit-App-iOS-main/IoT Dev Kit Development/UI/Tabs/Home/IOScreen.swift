//
//  IOScreen.swift
//  IoT Dev Kit Development
//
//  Created by Blake Bollinger on 3/8/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI
import UIKit

struct IOScreen: View {
    private var connectedBoard = Board.shared
    
    var body: some View {
        VStack {
            ScrollView {
                
                VStack(spacing: 24) {
                    
                    whiteLedView(connectedBoard: connectedBoard)
                    
                    rgbLedView(connectedBoard: connectedBoard)
                    
                    buzzerView(connectedBoard: connectedBoard)
                    
                    buttonView(connectedBoard: connectedBoard)
                    
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                
            }
            .background(Constants.backgroundColor)
        }
        .navigationTitle("I/O")
        .navigationBarTitleDisplayMode(.inline)
        
    }
}

private struct whiteLedView: View {
    @ObservedObject var connectedBoard: Board
    
    private var toggleLabel: some View {
        HStack {
            Text("White LED ")
                .font(.title2)
            LedStateIndicatorSymbolView(ledType: .white, connectedBoard: connectedBoard)
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.cellCornerRadius,
                             style: .continuous)
                .foregroundColor(.tmoWhite)
            
            Toggle(isOn: $connectedBoard.whiteLedOn) { toggleLabel }
                .tint(.tmoMagenta)
                .onChange(of: connectedBoard.whiteLedOn) { _ in
                    connectedBoard.updateLed()
                }
                .padding()
        }
    }
}

private struct rgbLedView: View {
    @ObservedObject var connectedBoard: Board

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.cellCornerRadius,
                             style: .continuous)
                .foregroundColor(.tmoWhite)

            VStack {
                HStack {
                    Text("RGB LED ")
                        .font(.title2)
                    LedStateIndicatorSymbolView(ledType: .rgb, connectedBoard: connectedBoard)
                        .accessibilityHidden(true)
                    Spacer()
                }
                Toggle("Red", isOn: $connectedBoard.redLedOn)
                    .onChange(of: connectedBoard.redLedOn) { _ in
                        connectedBoard.updateLed()
                    }
                Toggle("Green", isOn: $connectedBoard.greenLedOn)
                    .onChange(of: connectedBoard.greenLedOn) { _ in
                        connectedBoard.updateLed()
                    }
                Toggle("Blue", isOn: $connectedBoard.blueLedOn)
                    .onChange(of: connectedBoard.blueLedOn) { _ in
                        connectedBoard.updateLed()
                    }
            }
            .padding()
            .tint(.tmoMagenta)
        }
    }
}

private struct buzzerView: View {
    
    var connectedBoard: Board
    
    var body: some View {
        
        ZStack {
            
            RoundedRectangle(cornerRadius: Constants.cellCornerRadius, style: .continuous)
                .foregroundColor(.tmoWhite)
            
            VStack(alignment: .leading){
            
                HStack {
                Text("Buzzer")
                    .font(.title2)
                    Spacer()
                }
                
                Text("Press and hold the button to activate the buzzer.")
                    .padding(.vertical)
                
                Button(action: {
                    // Due to the long press gesture recognizer in the label below, this button action does nothing.
                    // TODO: When activated via accessibility technology like VoiceOver, we should send a short beep or toggle the buzzer state so accessibility users can interact with the buzzer. But it must not interfere with the long press gesture.
                }, label: {
                    ZStack {
                        Text("Activate Buzzer")
                            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 48)
                                    .stroke(Color.tmoMagenta, lineWidth: 2)
                            )
                    }
                })
                    .onLongPressGesture(perform: { /* NOP */ }, onPressingChanged: { pressing in
                        connectedBoard.buzzerOn = pressing
                        connectedBoard.updateLed()
                    })
            }
            .padding()
        }
    }
}

private struct buttonView: View {
    
    @ObservedObject var connectedBoard: Board
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.cellCornerRadius, style: .continuous)
                .foregroundColor(.tmoWhite)
            
            VStack(alignment: .leading) {
                
                HStack {
                Text("Button Status")
                    .font(.title2)
                    Spacer()
                }
                
                buttonIndicator(buttonPressed: connectedBoard.buttonPressed, colorScheme: colorScheme)
            }
            .padding()
        }
    }
}

private struct buttonIndicator: View {
    
    var buttonPressed: Bool
    var colorScheme: ColorScheme
    var title: String { self.buttonPressed ? " Pressed " : " Not pressed " }
    var titleColor: Color { self.buttonPressed ? .tmoWhite : .tmoGray60 }
    var buttonColor: Color {
        let green: Color = colorScheme == .light ? .tmoGreen : .tmoGreenLight
        return self.buttonPressed ? green : .tmoGray30
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(buttonColor)
                .frame(minWidth: 149, minHeight: 40)
            Text(title)
                .textCase(.uppercase)
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                .foregroundColor(titleColor)
        }
        .fixedSize()
    }
}

private struct Constants {
    static var backgroundColor = Color.tmoGray20
    static var cellCornerRadius: CGFloat = 4
}


struct IOScreen_Previews: PreviewProvider {
    static var previews: some View {
        IOScreen()
    }
}
