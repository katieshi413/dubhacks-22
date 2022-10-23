//
//  CardView.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 09/07/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import SwiftUI

/// A rounded rectangle view with a title, and an optional chevron to indicate navigation, at the top. The provided content views are laid out underneath in two columns, unless accessibility type sizes constricts the available space in which case a single column is used.
struct CardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Private properties
    private let title: String
    private let showChevron: Bool
    private let contentViews: [AnyView]

    /// All elements at even indices in the contentViews array.
    private var column1ContentViews: [AnyView] {
        return contentViews.enumerated().compactMap { tuple in
          tuple.offset.isMultiple(of: 2) ? tuple.element : nil
        }
    }

    /// All elements at odd indices in the contentViews array.
    private var column2ContentViews: [AnyView] {
        return contentViews.enumerated().compactMap { tuple in
          !tuple.offset.isMultiple(of: 2) ? tuple.element : nil
        }
    }

    /// - parameter title: The title of the card.
    /// - parameter showChevron: If `true` the card shows a chevron to indicate navigation. Defaults to `false`.
    /// - parameter contentViews: The views to display in the card.
    init(title: String, showChevron: Bool = false, contentViews: [AnyView]) {
        self.title = title
        self.showChevron = showChevron
        self.contentViews = contentViews
    }
    
    var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: Constants.cellCornerRadius, style: .continuous)
                    .foregroundColor(.tmoWhite)
                
                // Adapt layout to better fit content when using accessibility text sizes on compact devices.
                let shouldLayoutVertically = dynamicTypeSize.isAccessibilitySize && horizontalSizeClass == UserInterfaceSizeClass.compact

                VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                    
                    // The card title and an optional chevron.
                    HStack {
                        Text(title)
                            .font(.title2)
                        Spacer()
                        if showChevron {
                            Image(systemName: "chevron.forward")
                                .foregroundColor(.tmoGray40)
                                .font(.headline)
                        }
                    }
                    .padding([.top, .horizontal])
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                                        
                    // The card content.
                    // Laid out in 2 columns, unless accessibility text size is enabled and device size class is compact, a.k.a. when shouldLayoutVertically == true.
                    
                    if shouldLayoutVertically {
                        // There's not enough space to fit two columns. We fall back to a single column.
                        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                            ForEach(contentViews.indices, id: \.self) { contentViews[$0] }
                        }
                        .padding([.bottom, .leading])
                    } else {
                        // An HStack with 2 VStacks makes a layout where the column widths grow to fit their content independently, i.e. they can be different widths.
                        HStack(alignment: .center, spacing: Constants.valueSpacing) {
                            // Column 1.
                            VStack(alignment: .leading) {
                                ForEach(column1ContentViews.indices, id: \.self) { column1ContentViews[$0] }
                            }
                            // Column 2.
                            VStack(alignment: .leading) {
                                ForEach(column2ContentViews.indices, id: \.self) { column2ContentViews[$0] }
                            }
                        }
                        .padding([.bottom, .leading])
                    }
                }
            }
            .foregroundColor(.tmoGray70)
    }
}

/// A view with an `Image` followed by a `String`. Intended to be used for CardView content views.
struct CardIconValueView: View {
    let icon: Image
    let value: String

    var body: some View {
        HStack(alignment: .center) {
            icon
                .foregroundColor(.tmoMagenta)
            
            Text("\(value)")
                .font(.subheadline.monospacedDigit())
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .allowsTightening(true)
        }
    }
}

// MARK: - Constants
private struct Constants {
    static var cellCornerRadius: CGFloat = 4
    static var verticalSpacing: CGFloat = 16
    static var valueSpacing: CGFloat = 24
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(title: "Environment",
                     showChevron: true,
                 contentViews: [
                        AnyView( CardIconValueView(icon: Image("homeIconTemperature"), value: "21ºC") ),
                        AnyView( CardIconValueView(icon: Image("homeIconBarometer"), value: "1024 Pa") ),
                        AnyView( CardIconValueView(icon: Image("homeIconSun"), value: "141 lx") ),
                     ])
        .background(Color.gray)
    }
}

