// ContentView.swift
// InTraffic
// 루트 뷰 — 온보딩 게이트 + 3탭 메인 UI

import SwiftUI

struct ContentView: View {

    @State private var onboardingCompleted: Bool = AppSettings.onboardingCompleted

    let imdfStore: IMDFStore
    let densityService: DensityService
    let eventUploader: EventUploader
    let locationManager: LocationManager

    var body: some View {
        if onboardingCompleted {
            MainTabView(
                imdfStore: imdfStore,
                densityService: densityService,
                eventUploader: eventUploader,
                locationManager: locationManager
            )
        } else {
            OnboardingView {
                AppSettings.onboardingCompleted = true
                onboardingCompleted = true
            }
            .environment(locationManager)
        }
    }
}

// MARK: - 3탭 메인 뷰

private struct MainTabView: View {

    let imdfStore: IMDFStore
    let densityService: DensityService
    let eventUploader: EventUploader
    let locationManager: LocationManager

    var body: some View {
        TabView {
            // 지도 탭
            MapTabView(
                imdfStore: imdfStore,
                densityService: densityService,
                eventUploader: eventUploader,
                locationManager: locationManager
            )
            .tabItem {
                Label("지도", systemImage: "map.fill")
            }

            // 통계 탭
            StatsTabView(
                densityService: densityService,
                imdfStore: imdfStore
            )
            .tabItem {
                Label("통계", systemImage: "chart.bar.fill")
            }

            // 설정 탭
            SettingsView(locationManager: locationManager)
                .tabItem {
                    Label("설정", systemImage: "gearshape.fill")
                }
        }
    }
}
