//
//  AppController.swift
//  IoT Dev Kit Development
//
//  Created by Ahlberg, Kim on 2/1/22.
//  Copyright 2022 T-Mobile USA, Inc
//

import Foundation
import CoreBluetooth
import UIKit

/// The `AppController.shared` instance holds app view state and provides a few useful methods.
class AppController: ObservableObject {

    /// Links to pages the app can open in the system web browser.
    enum AppLink: String {
        case customerSupport = "https://devedge.t-mobile.com/contact"
        case faq = "https://rebrand.ly/k3bn8tf"
        case userGuide = "https://rebrand.ly/2b0409"
        case privacyPolicy = "https://www.t-mobile.com/privacy-center/our-practices/privacy-policy"
        case termsAndConditions = "https://www.t-mobile.com/responsibility/legal/terms-and-conditions"
    }
    
    // MARK: - Lifecycle
    
    // Singleton pattern with private initializer
    static let shared = AppController()
    private init() {
        // Set the initial values.
        shouldShowDeviceSelectionSheet = true
        shouldShowFirstLaunchScreen = true
        
        // Update the first launch state and device selection sheet state.
        shouldShowFirstLaunchScreen = firstLaunchState()
        shouldShowDeviceSelectionSheet = !shouldShowFirstLaunchScreen

        // Register to observe the Bluetooth state change notification.
        NotificationCenter.default.addObserver( self, selector: #selector( self.bluetoothStateDidChange(notification:) ), name: BluetoothManager.bluetoothStateDidChangeNotification, object: nil )
        // Register to observe the Bluetooth peripheral connection notification.
        NotificationCenter.default.addObserver( self, selector: #selector( self.bluetoothDidConnect ), name: BluetoothManager.bluetoothDidConnectPeripheralNotification, object: nil )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public properties
    
    @Published var shouldShowDeviceSelectionSheet: Bool // Used to indicate to the UI that the user intends to view the device selection UI.
    @Published var shouldShowFirstLaunchScreen: Bool // Used to indicate to the UI that first launch screen should be shown.
    
    /// A `String` containing the application's display name.
    static let formattedAppName: String = { Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "" }()
    
    /// A `String` containing the version of this application, followed by the build number in parenthesis.
    static let formattedAppVersion: String = {
        let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumberString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "\(versionString) (\(buildNumberString))"
    }()

    // MARK: - Public methods
    
    /// Opens the URL for the given `link` in the system's web browser.
    func open(link: AppLink) {
        guard let url = URL(string: link.rawValue) else { return }
        UIApplication.shared.open(url)
    }
    
    /// Opens the app settings in the system's Settings app.
    func openSettingsApp() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    /// Presents a share sheet for sharing the array of objects.
    /// On iPads the share sheet is presented in a popover which is aligned with the rightmost toolbar item in the navigation bar.
    func presentShareSheet(activityItems: [Any]) {

        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let keyWindow = windowScene.keyWindow
        else { return } // We need the keyWindow to be able to properly present the share sheet.

        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // Configure the popover location for use on devices that support it. E.g. iPads.
        // We set the sourceRect to match where a navigation bar's trailing button is expected to appear.
        // The offsets were arrived at by experimentation, taking the window safe area insets into account.
        let insets = keyWindow.safeAreaInsets
        let xOffset = keyWindow.bounds.width - 40 - insets.right
        let yOffset = 12 + insets.top
        let sourceRect = CGRect(x: xOffset, y: yOffset, width: 24, height: 24) // 24 x 24 pt. rectangle.
        
        activityViewController.popoverPresentationController?.permittedArrowDirections = [.up]
        activityViewController.popoverPresentationController?.sourceView = keyWindow
        activityViewController.popoverPresentationController?.sourceRect = sourceRect
        
        keyWindow.rootViewController?.present(activityViewController, animated: true)
    }
}

// MARK: - Private methods

private extension AppController {
    static let firstLaunchHasOccurredKey = "firstLaunchHasOccurred"
    
    /// Method to figure out if we should treat this as the first launch of the app.
    /// The return value is based on the Bluetooth authorization state and whether the app has been launched previously.
    /// This method stores a value in the user defaults to record that the app has been launched, for future reference.
    func firstLaunchState() -> Bool {
        let userDefaults = UserDefaults.standard

        // Read the first launch state from the user defaults, and the bluetooth authorization state.
        let firstLaunchAlreadyOccurred = userDefaults.bool(forKey: AppController.firstLaunchHasOccurredKey)
        let firstLaunch = !firstLaunchAlreadyOccurred
        let bluetoothNotDetermined = CBCentralManager.authorization == .notDetermined
        
        // Update the user defaults first launch state.
        if !firstLaunchAlreadyOccurred {
            userDefaults.set(true, forKey: AppController.firstLaunchHasOccurredKey)
        }
        
        // We return true either if this is the first launch, *or* if the user hasn't set a Bluetooth authorization yet.
        return firstLaunch || bluetoothNotDetermined
    }

    @objc func bluetoothStateDidChange(notification: NSNotification) {
        // Update the shouldShowFirstLaunchScreen property to dismiss the first launch screen if it is showing.
        shouldShowFirstLaunchScreen = false
        
        // Update the shouldShowDeviceSelectionSheet property during a later run-loop to make it animate into view if Bluetooth is now powered on and ready to use.
        if let bluetoothManager = notification.object as? BluetoothManager, bluetoothManager.isBluetoothAvailable {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now().advanced(by: DispatchTimeInterval.milliseconds(100))) {
                self.shouldShowDeviceSelectionSheet = true
            }
        }
    }
    
    @objc func bluetoothDidConnect() {
        // When a Bluetooth peripheral successfully connects, we automatically dismiss the device selection sheet.
        shouldShowDeviceSelectionSheet = false
    }
}
