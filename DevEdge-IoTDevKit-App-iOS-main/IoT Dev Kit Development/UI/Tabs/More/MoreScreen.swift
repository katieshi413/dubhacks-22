//
//  MoreScreen.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 11/16/21.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

/// A view that provides app information and links to external documents and the system Settings app.
/// If a Bluetooth connection is active the IMEI of the connected board is also shown.
struct MoreScreen: View {
    
    var body: some View {
        
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        SettingsHeader()
                            .padding()
                        
                        VStack {
                            
                            Button {
                                AppController.shared.openSettingsApp()
                            } label: {
                                SettingsListItem(icon: "gear", text: "App Settings")
                            }
                            
                            Button {
                                AppController.shared.open(link: .faq)
                            } label: {
                                SettingsListItem(icon: "doc.text", text: "FAQ")
                            }
                            
                            Button {
                                AppController.shared.open(link: .customerSupport)
                            } label: {
                                SettingsListItem(icon: "ellipsis.bubble", text: "Customer Support")
                            }
                            
                            NavigationLink(destination: AboutView()){
                                SettingsListItem(icon: "info.circle", text: "About")
                            }
                            
                            Spacer()
                            
                            Text("\(AppController.formattedAppName) version \(AppController.formattedAppVersion)")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .background(Color.tmoWhite)
                    }
                    .frame(minHeight: geometry.size.height, maxHeight: .infinity)
                }
                .foregroundColor(.tmoGray70)
                .background(Color.tmoGray10)
                
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            }
            .navigationTitle("Settings")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}

struct SettingsHeader: View {
    @ObservedObject var connectedBoard = Board.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Text(connectedBoard.formattedBoardName)
                .font(.title)
                .padding(.top, 8)
            
            Text(connectedBoard.isConnected ? "IMEI: \(connectedBoard.boardIMEI)" : "")
                .textSelection(.enabled)
                .font(.caption)
            
            ZStack {
                Circle()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.tmoWhite)
                Image("boardIcon")
                    .foregroundColor(.tmoMagenta)
            }
            .padding(.top, 8)
        }
    }
}

struct SettingsListItem: View {
    
    var icon: String?
    var text: String
    
    var body: some View {
        HStack {
            if icon != nil {
                Image(systemName: icon!)
                    .frame(width: 24)
            }
            Text(text)
            
            Spacer()
            
            Image(systemName: "chevron.right")
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
    }
}

struct MoreScreen_Previews: PreviewProvider {
    static var previews: some View {
        MoreScreen()
    }
}
