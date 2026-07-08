//
//  BannerAdView.swift
//  weather
//

import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    // Test ad ID so ads are visible during App Review (swap back to real ID after approval)
    private let adUnitID = "ca-app-pub-3940256099942544/2934735716"

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        // Defer load until after the view is in the window hierarchy
        DispatchQueue.main.async {
            guard !context.coordinator.hasLoaded else { return }
            guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.keyWindow?.rootViewController else { return }
            context.coordinator.hasLoaded = true
            banner.rootViewController = rootVC
            banner.load(Request())
        }
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        guard !context.coordinator.hasLoaded else { return }
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.keyWindow?.rootViewController else { return }
        context.coordinator.hasLoaded = true
        uiView.rootViewController = rootVC
        uiView.load(Request())
    }

    class Coordinator {
        var hasLoaded = false
    }
}
