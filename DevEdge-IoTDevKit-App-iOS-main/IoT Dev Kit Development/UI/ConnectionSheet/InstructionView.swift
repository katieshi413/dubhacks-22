//
//  InstructionView.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 2/4/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

/// A view instructing the user about how to connect the app to their Bluetooth board.
struct InstructionView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var ringOpacity = 1.0
    @State private var ringScale = 0.5
    @State private var instructionsOpacity = 0.0
    private let instructionsDelay = 10.0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .center){

                    Spacer()

                    HStack {
                        Spacer()
                        Text("Searching for devices…")
                            .font(.title)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    
                    Spacer()
                    
                    ZStack {
                        // Illustration: Animated pulsating rings around a Bluetooth logo.
                        Image("instructionRings")
                            .renderingMode(.template)
                            .foregroundColor(.tmoGray50)
                            .opacity(ringOpacity)
                            .scaleEffect(x: ringScale, y: ringScale)
                            .accessibilityHidden(true)
                        Image("instructionBluetoothLogo")
                            .foregroundColor(.tmoMagenta)
                            .accessibilityLabel("Bluetooth logotype")
                    }
                    
                    Spacer()
                    
                    Text("Make sure your DevEdge device is near your phone and powered on.")
                        .multilineTextAlignment(.center)
                        .opacity(instructionsOpacity)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Button {
                        AppController.shared.open(link: .userGuide)
                    } label: {
                        Image.init(systemName: "doc.text")
                        Text("User Guide")
                    }
                    .foregroundColor(.tmoMagenta)
                    .opacity(instructionsOpacity)
                    
                    Spacer()
                    
                }
                .padding(.horizontal)
                .foregroundColor(.tmoGray70)
                .frame(minHeight: geometry.size.height, maxHeight: .infinity)
                .onAppear {
                    
                    // Start animating the pulsating rings around the Bluetooth logo, unless the user has enabled the Reduce Motion setting.
                    if (!reduceMotion) {
                        withAnimation(Animation.easeOut(duration: 2).repeatForever(autoreverses: false), {
                            self.ringScale = 1.25
                            self.ringOpacity = 0.0
                        })
                    }
                    
                    // Reveal the instructions text after a delay.
                    withAnimation(Animation.easeIn.delay(instructionsDelay), {
                        self.instructionsOpacity = 1.0
                    })
                }
            }
        }
    }
}

struct InstructionView_Previews: PreviewProvider {
    static var previews: some View {
        InstructionView()
    }
}
