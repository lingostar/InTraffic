// OnboardingView.swift
// InTraffic

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    let onComplete: () -> Void

    @Environment(LocationManager.self) private var locationManager

    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingPage1().tag(0)
            OnboardingPage2().tag(1)
            OnboardingPage3(
                locationManager: locationManager,
                onComplete: onComplete
            ).tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .ignoresSafeArea(edges: .bottom)
        .animation(.easeInOut, value: currentPage)
        .overlay(alignment: .bottom) {
            if currentPage < 2 {
                Button {
                    withAnimation { currentPage += 1 }
                } label: {
                    Text("다음")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 52)
            }
        }
    }
}

// MARK: - Page 1

private struct OnboardingPage1: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "map.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            Text("InTraffic")
                .font(.largeTitle.bold())
            Text("실내 혼잡도 실시간 안내")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("지금 어디가 붐비는지,\n어디가 한산한지 바로 확인하세요.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Page 2

private struct OnboardingPage2: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("어떻게 작동하나요?")
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "shield.fill", color: .blue,
                           title: "개인정보 없음",
                           desc: "이름·연락처는 절대 수집하지 않습니다.")
                FeatureRow(icon: "mappin.and.ellipse", color: .green,
                           title: "구역 단위 익명 집계",
                           desc: "어느 구역에 있는지만 숫자로 모읍니다.")
                FeatureRow(icon: "battery.100.bolt", color: .orange,
                           title: "배터리 절약",
                           desc: "위치가 크게 변할 때만 수집합니다.")
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(desc).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Page 3

private struct OnboardingPage3: View {
    let locationManager: LocationManager
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 72))
                .foregroundStyle(.purple)
            Text("위치 권한이 필요합니다")
                .font(.largeTitle.bold())
            Text("정확한 혼잡도 측정을 위해\n**'항상 허용'** 을 선택해 주세요.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 12) {
                Button {
                    locationManager.requestAlwaysAuthorization()
                } label: {
                    Label("위치 권한 허용", systemImage: "location.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    onComplete()
                } label: {
                    Text("나중에 설정하기")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)
            Spacer()
        }
        .onChange(of: locationManager.authorizationStatus) { _, status in
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                onComplete()
            }
        }
    }
}
