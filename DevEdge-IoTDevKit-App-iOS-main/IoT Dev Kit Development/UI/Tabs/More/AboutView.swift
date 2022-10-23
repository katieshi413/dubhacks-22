//
//  AboutView.swift
//  IoT Dev Kit Development
//
//  Created by Blake Bollinger on 7/8/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

/// A view that provides external links to documents describing the Terms and Conditions and Privacy Policy.
struct AboutView: View {
    var body: some View {

        ScrollView {
            
            VStack {
                
                Button {
                    AppController.shared.open(link: .termsAndConditions)
                } label: {
                    SettingsListItem(text: "Terms and Conditions")
                }
                
                Button {
                    AppController.shared.open(link: .privacyPolicy)
                } label: {
                    SettingsListItem(text: "Privacy Policy")
                }
                
            }
            
        }
        .padding(.top, 16)
        .foregroundColor(.tmoGray70)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("About")

    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
