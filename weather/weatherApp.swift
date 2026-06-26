//
//  weatherApp.swift
//  weather
//

import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct weatherApp: App {
    init() {
        MobileAds.shared.start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { requestTracking() }
        }
    }

    private func requestTracking() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
