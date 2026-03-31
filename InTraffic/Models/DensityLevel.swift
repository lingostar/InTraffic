// DensityLevel.swift
// InTraffic

import SwiftUI

/// Zone의 혼잡도 단계
enum DensityLevel: String, Codable, CaseIterable {
    case low        // 여유  (0~3명)
    case moderate   // 보통  (4~8명)
    case busy       // 혼잡  (9~15명)
    case crowded    // 매우혼잡 (16명~)
    case unknown    // 데이터 없음

    // MARK: - 명칭

    var label: String {
        switch self {
        case .low:      "여유"
        case .moderate: "보통"
        case .busy:     "혼잡"
        case .crowded:  "매우 혼잡"
        case .unknown:  "정보 없음"
        }
    }

    // MARK: - Apple System Color 기반

    var color: Color {
        switch self {
        case .low:      Color(UIColor.systemGreen)
        case .moderate: Color(UIColor.systemYellow)
        case .busy:     Color(UIColor.systemOrange)
        case .crowded:  Color(UIColor.systemRed)
        case .unknown:  Color(UIColor.systemGray4)
        }
    }

    var fillColor: Color {
        color.opacity(0.45)
    }

    var strokeColor: Color {
        color.opacity(0.85)
    }

    // MARK: - 카운트에서 변환

    static func from(count: Int) -> DensityLevel {
        switch count {
        case 0...3:   .low
        case 4...8:   .moderate
        case 9...15:  .busy
        default:      .crowded
        }
    }
}
