//
//  UIImage.swift
//  IoT Dev Kit Development
//
//  Created by Blake Bollinger on 6/8/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import Foundation
import UIKit

extension UIImage{
    
    // This extension allows us to overlay one UIImage on top of another
    //
    /// - parameter topImage: The `UIImage` to overlay
    /// - returns: A new `UIImage` that contains the generated output
    func overlay(_ topImage: UIImage?) -> UIImage {
        
        guard let topImage = topImage else {
            print("Nil image value found when trying to overlay UIImage")
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let actualArea = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let overlayArea = CGRect(x: 0, y: size.height - topImage.size.height, width: size.width, height: topImage.size.height)
        self.draw(in: actualArea)
        topImage.draw(in: overlayArea)
        let generatedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return generatedImage
        
    }

    /// Returns a tinted template `UIImage` for the given image name, or a fallback image if no image in the asset catalog matches the name.
    ///
    /// - parameter name: The name of the image asset or file.
    /// - parameter tintColor: A `UIColor` to color the `topImage` with, or nil to use the `topImage` as provided.
    /// - returns: A new `UIImage` that contains the template image tinted with the `tintColor`, or a fallback image.
    static func template(named name: String, tintColor: UIColor) -> UIImage {
        
        guard let namedImage = UIImage(named: name) else {
            print("Nil image value found when looking for \"\(name)\"")

            if let fallbackImage = UIImage(systemName: "questionmark.app.dashed") {
                return fallbackImage
            } else {
                return UIImage()
            }
        }
        
        return namedImage.withTintColor(tintColor, renderingMode: .alwaysTemplate)
    }
}
