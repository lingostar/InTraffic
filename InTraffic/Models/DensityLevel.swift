// DensityLevel.swift
// InTraffic
//
// 3m x 3m (9m²) 셀 기준 혼잡도 단계
// NFPA / UK Green Guide 기반 밀도 기준

import SwiftUI

/// Zone의 혼잡도 단계 — 9m² (3x3m) 셀 기준 인원 수
enum DensityLevel: String, Codable, CaseIterable {
    case low        // 여유     0~4명/9m²    (~0.4인/m²)
    case moderate   // 보통     5~9명/9m²    (~1.0인/m²)
    case busy       // 혼잡    10~17명/9m²   (~1.9인/m²)
    case crowded    // 매우혼잡 18~44명/9m²   (2.0인/m² — NFPA 안전 한계)
    case extreme    // 위험    45명~/9m²     (5.0인/m² — 극심 혼잡/위험)
    case unknown    // 데이터 없음

    // MARK: - 명칭

    var label: String {
        switch self {
        case .low:      "여유"
        case .moderate: "보통"
        case .busy:     "혼잡"
        case .crowded:  "매우 혼잡"
        case .extreme:  "위험"
        case .unknown:  "정보 없음"
        }
    }

    // MARK: - 색상

    var color: Color {
        switch self {
        case .low:      Color(UIColor.systemGreen)
        case .moderate: Color(UIColor.systemYellow)
        case .busy:     Color(UIColor.systemOrange)
        case .crowded:  Color(UIColor.systemRed)
        case .extreme:  Color.black
        case .unknown:  Color(UIColor.systemGray4)
        }
    }

    var fillColor: Color {
        color.opacity(0.45)
    }

    var strokeColor: Color {
        color.opacity(0.85)
    }

    // MARK: - 9m² 셀 기준 환산 밀도에서 변환

    /// countPerCell: Zone의 면적을 9m² 셀로 나눈 후 환산한 인원 수
    /// 예) 100m² Zone에 20명 → countPerCell = 20 * 9 / 100 = 1.8
    static func from(countPerCell: Double) -> DensityLevel {
        switch countPerCell {
        case ..<5:    .low         //  0~4명/9m²
        case 5..<10:  .moderate    //  5~9명/9m²
        case 10..<18: .busy        // 10~17명/9m²
        case 18..<45: .crowded     // 18~44명/9m² (NFPA 안전 한계)
        default:      .extreme     // 45명~/9m²  (극심 혼잡)
        }
    }

    /// 절대 인원 기반 (면적 정보 없는 경우, Stats 탭 등)
    static func from(count: Int) -> DensityLevel {
        switch count {
        case 0...4:   .low
        case 5...9:   .moderate
        case 10...17: .busy
        case 18...44: .crowded
        default:      .extreme
        }
    }
}
