//
//  SettingsScreen.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 11/16/21.
//

import SwiftUI

struct SettingsScreen: View {
    var body: some View {
        
        VStack {
            
            VStack(spacing: 0) {
            
                VStack {
                    
                    Text("DevEdge Board 1")
                        .padding(.bottom, 16)
                        .font(.title)
                        .foregroundColor(.tmoGray70)
                    
                    ZStack {
                    
                        Circle()
                            .frame(width: 64, height: 64)
                            .colorInvert()
                        Image(uiImage: UIImage(named: "boardIcon")!)
                            .foregroundColor(.tmoMagenta)
                        
                    }
                    
                }
                .frame(height: 178)
                
                Group {
                
                    Button {
                        print("App Notifications tapped")
                    } label: {
                        ListItem(icon: "bell.badge", text: "App Notifications")
                    }
                    
                    Button {
                        print("FAQs tapped")
                    } label: {
                        ListItem(icon: "questionmark.circle", text: "FAQs")
                    }
                    
                    Button {
                        print("Customer Support tapped")
                    } label: {
                        ListItem(icon: "phone", text: "Customer Support")
                    }
                    
                    Button {
                        print("About tapped")
                    } label: {
                        ListItem(icon: "doc.text", text: "About")
                    }
                }
                .background(Color.white)
                
                ZStack(alignment: .bottom) {
                    
                    Rectangle()
                        .colorInvert()
                    
                    Text("T-Mobile DevEdge Board version 0.0.1 (12345)")
                        .font(.caption)
                        .padding(.bottom, 24)
                        .foregroundColor(.tmoGray70)
                        .multilineTextAlignment(.center)
                }

                
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .background(Color.tmoGray10)
            
            Spacer(minLength: 1)
        }
    }
}

struct TabBarAccessor: UIViewControllerRepresentable {
    var callback: (UITabBar) -> Void
    private let proxyController = ViewController()

    func makeUIViewController(context: UIViewControllerRepresentableContext<TabBarAccessor>) ->
                              UIViewController {
        proxyController.callback = callback
        return proxyController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<TabBarAccessor>) {
    }

    typealias UIViewControllerType = UIViewController

    private class ViewController: UIViewController {
        var callback: (UITabBar) -> Void = { _ in }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if let tabBar = self.tabBarController {
                self.callback(tabBar.tabBar)
            }
        }
    }
}

struct ListItem: View {
    
    var icon: String
    var text: String

    var body: some View {
        
        HStack {
            
            Image(systemName: icon)
                .foregroundColor(.tmoGray70)
            
            Text(text)
                .foregroundColor(.tmoGray70)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.tmoGray70)
            
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        
    }
    
}

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        SettingsScreen()
            .previewDevice("iPod touch (7th generation)")
        SettingsScreen()
            .previewDevice("iPhone 12 Pro Max")
    }
}
