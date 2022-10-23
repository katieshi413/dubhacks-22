//
//  DebugScreen.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 11/17/21.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

/// A view that shows debug output from Bluetooth connections and communications.
struct DebugScreen: View {
    
    @ObservedObject private var logger = Logger.shared
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer(minLength: 0.25) // This stops our scroll view from going underneath the navigation bar.
                
                ScrollView {
                    
                    LazyVStack {
                        if logger.loggedEvents.isEmpty {
                            
                            Text("No debug logs available")
                                .foregroundColor(.uniGray10)
                                .padding(.top, 15)
                            
                        } else {
                            
                            ForEach(logger.loggedEvents) { logEvent in
                                DebugEvent(event: logEvent)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                }
                .background(Color.tmoGray80)
                
                Spacer(minLength: 0.25) // This stops our scroll view from going underneath the tab bar.
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(){
                ToolbarItemGroup(placement: .navigationBarLeading){
                    Button("Devices"){
                        AppController.shared.shouldShowDeviceSelectionSheet = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing){
                    Button (action: shareSheet) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    func shareSheet() {
        var debugItemsStrings: [String] = []
        if !logger.loggedEvents.isEmpty {
            var temp : String
            for log in logger.loggedEvents {
                temp = log.formattedTimestamp + "\n" + log.message + "\n"
                debugItemsStrings.append(temp)
            }
        } else {
            debugItemsStrings.append("no logs")
        }
        
        AppController.shared.presentShareSheet(activityItems: debugItemsStrings)
    }
}

func getDate()->String{
    let time = Date()
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:ss"
    let stringDate = timeFormatter.string(from: time)
    return stringDate
}

// TODO: Document what this function is meant to accomplish.
func splitText(text: String) -> [Text] {
    let segments = text.components(separatedBy: " ")
    var accentColor: [[String]] = [[segments[0], "red"]]

    for i in 1..<segments.count {
        accentColor.append([segments[i], "0"])
        if segments[i].last == ":" {
            accentColor[i][1] = "red"
        }
    }
    
    var textViews: [Text] = []
    
    for i in accentColor {
        if let first = i.first,
           let second = i.elementAt(index: 1)
        {
            let color: Color
            if second == "0" {
                color = Color.uniGray10
            } else {
                color = Color.tmoOrange
            }
            
            let textView = Text(first)
                .font(.custom("Courier", size: 15, relativeTo: .body))
                .foregroundColor(color)
            textViews.append(textView)
        }
    }
    
    return textViews
}

// TODO: Document what this recursive function is meant to accomplish. Does it concatenate the texts? Then it should be named concatenateTexts(views: ).
func sumViews(views: [Text]) -> Text {

    // Protect against crashes due to being called with an empty array.
    guard let first = views.first else { return Text("") }
    
    // The recursive base case.
    if views.count == 1 {
        return first
    }
    
    var mutableViews = views
    mutableViews.removeFirst()
    
    // Call this function recursively to add the remaining views.
    return first + Text(" ") + sumViews(views: mutableViews)
}

struct DebugEvent: View {
    var event: Logger.LogEvent
    var time: String { event.formattedTimestamp }
    var rawEventData: String { event.message }
    
    var styledEventData: Text {
        return sumViews(views: splitText(text: rawEventData))
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            Text(time)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
                .font(.title3)
            
            styledEventData
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
            
        }
        .padding(12)
    }
}

struct DebugScreen_Previews: PreviewProvider {
    static var previews: some View {
        DebugScreen().preferredColorScheme(.dark)
        
    }
}
