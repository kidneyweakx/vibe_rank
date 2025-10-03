//
//  AdMobBannerView.swift
//  viberanking
//
//  Created by Assistant on 2025/10/03.
//

import SwiftUI
import GoogleMobileAds
import UIKit

// MARK: - AdMob Banner View (SwiftUI Wrapper)

struct AdMobBannerView: UIViewRepresentable {
    let adUnitID: String

    init(adUnitID: String = "ca-app-pub-3940256099942544/2934735716") {
        // Default test ad unit ID - replace with your actual ad unit ID in production
        self.adUnitID = adUnitID
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = getRootViewController()
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }

    class Coordinator: NSObject, BannerViewDelegate {
        var parent: AdMobBannerView

        init(_ parent: AdMobBannerView) {
            self.parent = parent
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ AdMob: Banner ad loaded successfully")
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ AdMob: Failed to load banner ad - \(error.localizedDescription)")
        }

        func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            print("📊 AdMob: Banner ad impression recorded")
        }

        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            print("👆 AdMob: Banner ad tapped")
        }

        func bannerViewWillDismissScreen(_ bannerView: BannerView) {
            print("👋 AdMob: Banner ad dismissing")
        }

        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            print("✅ AdMob: Banner ad dismissed")
        }
    }
}

// MARK: - Adaptive Banner View (Responsive for iPad)

struct AdMobAdaptiveBannerView: UIViewRepresentable {
    let adUnitID: String

    init(adUnitID: String = "ca-app-pub-3940256099942544/2934735716") {
        // Default test ad unit ID - replace with your actual ad unit ID in production
        self.adUnitID = adUnitID
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView()
        banner.adUnitID = adUnitID
        banner.rootViewController = getRootViewController()
        banner.delegate = context.coordinator

        // Use adaptive banner size for better responsive design
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let frame = window.frame.inset(by: window.safeAreaInsets)
            let viewWidth = frame.size.width
            banner.adSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
        }

        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // Update ad size on rotation or size changes
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let frame = window.frame.inset(by: window.safeAreaInsets)
            let viewWidth = frame.size.width
            let newAdSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)

            if !isAdSizeEqualToSize(size1: uiView.adSize, size2: newAdSize) {
                uiView.adSize = newAdSize
                uiView.load(Request())
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }

    class Coordinator: NSObject, BannerViewDelegate {
        var parent: AdMobAdaptiveBannerView

        init(_ parent: AdMobAdaptiveBannerView) {
            self.parent = parent
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ AdMob Adaptive: Banner ad loaded successfully")
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ AdMob Adaptive: Failed to load banner ad - \(error.localizedDescription)")
        }

        func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            print("📊 AdMob Adaptive: Banner ad impression recorded")
        }

        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            print("👆 AdMob Adaptive: Banner ad tapped")
        }

        func bannerViewWillDismissScreen(_ bannerView: BannerView) {
            print("👋 AdMob Adaptive: Banner ad dismissing")
        }

        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            print("✅ AdMob Adaptive: Banner ad dismissed")
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Text("Standard Banner")
            .font(.headline)
        AdMobBannerView()
            .frame(height: 50)

        Text("Adaptive Banner")
            .font(.headline)
        AdMobAdaptiveBannerView()
            .frame(height: 90)
    }
    .background(Color.black)
}
