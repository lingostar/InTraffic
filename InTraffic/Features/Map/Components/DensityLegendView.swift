// DensityLegendView.swift
// InTraffic
// 지도 하단 혼잡도 범례

import SwiftUI

struct DensityLegendView: View {
    private let visibleLevels: [DensityLevel] = [.low, .moderate, .busy, .crowded, .extreme]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(visibleLevels, id: \.self) { level in
                HStack(spacing: 4) {
                    Circle()
                        .fill(level.color)
                        .frame(width: 8, height: 8)
                    Text(level.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}
