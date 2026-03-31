// InTrafficApp.swift
// InTraffic
// 앱 진입점 — 싱글톤 서비스 생성 및 ContentView 제공

import SwiftUI

@main
struct InTrafficApp: App {

    // MARK: - Core Services (앱 수명 동안 단일 인스턴스)

    @State private var imdfStore     = IMDFStore()
    @State private var locationManager = LocationManager()

    private let densityService = DensityService()
    private let eventUploader  = EventUploader()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView(
                imdfStore: imdfStore,
                densityService: densityService,
                eventUploader: eventUploader,
                locationManager: locationManager
            )
            .task {
                // IMDF 데이터 비동기 로드 (앱 시작 즉시)
                await imdfStore.load()
            }
        }
    }
}
