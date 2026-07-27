//
//  weatherApp.swift
//  weather
//

import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct weatherApp: App {
    @State private var purchaseManager = PurchaseManager()
    @State private var showSplash = true

    init() {
        MobileAds.shared.start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(purchaseManager: purchaseManager)
                    .onAppear { requestTracking() }
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showSplash)
            .task {
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                showSplash = false
            }
        }
    }

    private func requestTracking() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.35, blue: 0.75),
                         Color(red: 0.15, green: 0.55, blue: 0.90)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(.white)

                    Text("Place Pulse")
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Discover any city")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))
                }

                Spacer()

                Image("nyc_skyline")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .opacity(0.9)
                    .padding(.bottom, 60)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}
