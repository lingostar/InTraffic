// ZoneDetailSheet.swift
// InTraffic
// Zone 탭 시 나타나는 하단 시트

import SwiftUI
import Charts

struct ZoneDetailSheet: View {
    let zone: ZonePolygon
    let density: ZoneDensity?
    let hourlyData: [HourlyDensity]
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 핸들 + 닫기
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(UIColor.systemGray4))
                    .frame(width: 36, height: 4)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 8)

            // 헤더
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(zone.category.capitalized)
                        .font(.title3.bold())
                    if let density {
                        Text("현재 약 \(density.currentCount)명")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("데이터 수집 중...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let density {
                    DensityBadge(level: density.densityLevel)
                }
            }
            .padding(.horizontal, 20)

            // 시간대별 차트
            if !hourlyData.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("오늘 시간대별 방문자")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 20)

                    Chart(hourlyData) { data in
                        AreaMark(
                            x: .value("시간", data.hour),
                            y: .value("방문자", data.count)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0.05)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        LineMark(
                            x: .value("시간", data.hour),
                            y: .value("방문자", data.count)
                        )
                        .foregroundStyle(Color.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: 2)) { value in
                            AxisValueLabel {
                                if let hour = value.as(Int.self) {
                                    Text("\(hour)시")
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let count = value.as(Int.self) {
                                    Text("\(count)")
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(height: 120)
                    .padding(.horizontal, 20)
                }
            }

            Spacer()
        }
        .background(Color(UIColor.systemBackground))
        .presentationDetents([.height(300), .large])
        .presentationBackgroundInteraction(.enabled)
    }
}

// MARK: - 혼잡도 배지

struct DensityBadge: View {
    let level: DensityLevel

    var body: some View {
        Text(level.label)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(level.color.opacity(0.15))
            .foregroundStyle(level.color)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(level.color.opacity(0.4), lineWidth: 1)
            )
    }
}
