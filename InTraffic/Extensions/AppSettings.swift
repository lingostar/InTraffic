// AppSettings.swift
// InTraffic
// UserDefaults 키 상수 모음

import Foundation

enum AppSettings {
    /// 데이터 수집 참여 여부 (기본값: true)
    static let participationKey = "inTraffic.participatesInDataCollection"

    /// 온보딩 완료 여부
    static let onboardingCompletedKey = "inTraffic.onboardingCompleted"

    /// 익명 ID (AnonymousID.swift 에서 동일 키 사용)
    static let anonymousIdKey = "com.intrafficapp.anonymousId"

    // MARK: - Helpers

    static var participatesInDataCollection: Bool {
        get {
            // 최초 실행이면 UserDefaults에 키가 없으므로 true 를 기본값으로 처리
            if UserDefaults.standard.object(forKey: participationKey) == nil {
                UserDefaults.standard.set(true, forKey: participationKey)
                return true
            }
            return UserDefaults.standard.bool(forKey: participationKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: participationKey)
        }
    }

    static var onboardingCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: onboardingCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardingCompletedKey) }
    }
}
