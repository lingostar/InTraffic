// SettingsView.swift
// InTraffic
// 설정 탭 – 위치 권한 상태 · 데이터 수집 토글 · 개인정보 안내

import SwiftUI
import CoreLocation

struct SettingsView: View {

    @State private var viewModel: SettingsViewModel

    init(locationManager: LocationManager) {
        _viewModel = State(initialValue: SettingsViewModel(locationManager: locationManager))
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: 위치 권한 섹션
                Section {
                    LocationStatusRow(status: viewModel.authorizationStatus)

                    if viewModel.authorizationStatus != .authorizedAlways {
                        Button {
                            viewModel.openSystemSettings()
                        } label: {
                            Label("시스템 설정에서 권한 변경", systemImage: "gear")
                        }
                    }
                } header: {
                    Text("위치 권한")
                } footer: {
                    Text("항상 허용 시 백그라운드에서도 혼잡도 측정에 기여합니다.")
                }

                // MARK: 데이터 수집 섹션
                Section {
                    Toggle(isOn: $viewModel.participatesInDataCollection) {
                        Label("데이터 수집 참여", systemImage: "chart.bar.fill")
                    }
                } header: {
                    Text("데이터 수집")
                } footer: {
                    Text("본인의 위치 데이터를 익명으로 제출하여 실내 혼잡도 측정에 기여합니다. 이름·연락처 등 개인정보는 수집하지 않습니다.")
                }

                // MARK: 개인정보 섹션
                Section("개인정보") {
                    LabeledContent("익명 ID") {
                        Text(viewModel.anonymousIdPrefix)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        viewModel.showResetConfirmation = true
                    } label: {
                        Label("익명 ID 재설정", systemImage: "arrow.counterclockwise")
                    }
                }

                // MARK: 앱 정보 섹션
                Section("앱 정보") {
                    LabeledContent("버전") {
                        Text(viewModel.appVersion)
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/lingostar/InTraffic")!) {
                        Label("GitHub 저장소", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .navigationTitle("설정")
            .confirmationDialog(
                "익명 ID를 재설정하면 기존 기여 기록이 새 ID로 분리됩니다. 계속하시겠습니까?",
                isPresented: $viewModel.showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("재설정", role: .destructive) {
                    viewModel.resetAnonymousId()
                }
                Button("취소", role: .cancel) {}
            }
        }
    }
}

// MARK: - 위치 권한 상태 행

private struct LocationStatusRow: View {
    let status: CLAuthorizationStatus

    var body: some View {
        HStack {
            Label(statusLabel, systemImage: statusIcon)
            Spacer()
            Text(statusDescription)
                .font(.caption)
                .foregroundStyle(statusColor)
        }
    }

    private var statusLabel: String { "현재 권한 상태" }

    private var statusIcon: String {
        switch status {
        case .authorizedAlways:   return "location.fill"
        case .authorizedWhenInUse: return "location"
        case .denied, .restricted: return "location.slash.fill"
        default:                  return "location.slash"
        }
    }

    private var statusDescription: String {
        switch status {
        case .authorizedAlways:    return "항상 허용"
        case .authorizedWhenInUse: return "앱 사용 중"
        case .denied:              return "거부됨"
        case .restricted:          return "제한됨"
        case .notDetermined:       return "미결정"
        @unknown default:          return "알 수 없음"
        }
    }

    private var statusColor: Color {
        switch status {
        case .authorizedAlways:    return .green
        case .authorizedWhenInUse: return .orange
        default:                   return .red
        }
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class SettingsViewModel {

    var showResetConfirmation = false

    private let locationManager: LocationManager

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }

    // MARK: - Computed

    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    var participatesInDataCollection: Bool {
        get { AppSettings.participatesInDataCollection }
        set { AppSettings.participatesInDataCollection = newValue }
    }

    var anonymousIdPrefix: String {
        let full = AnonymousID.shared.value
        return String(full.prefix(8)) + "…"
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Actions

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func resetAnonymousId() {
        UserDefaults.standard.removeObject(forKey: AppSettings.anonymousIdKey)
        // AnonymousID.shared.value 는 다음 접근 시 새 UUID 생성
    }
}
