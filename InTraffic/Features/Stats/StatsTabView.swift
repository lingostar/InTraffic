// StatsTabView.swift
// InTraffic
// 통계 탭 – Top 3 혼잡 구역 · 층별 혼잡도 바 차트 · 시간대별 추이

import SwiftUI
import Charts

struct StatsTabView: View {

    @State private var viewModel: StatsTabViewModel

    init(densityService: DensityService, imdfStore: IMDFStore) {
        _viewModel = State(initialValue: StatsTabViewModel(
            densityService: densityService,
            imdfStore: imdfStore
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.zoneDensities.isEmpty {
                    ProgressView("불러오는 중…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // MARK: Top 3
                            TopZonesSection(zones: viewModel.topZones)

                            // MARK: 층별 평균 혼잡도
                            FloorBarChartSection(floorStats: viewModel.floorStats)

                            // MARK: 오늘 시간대별 전체 방문자
                            HourlyLineChartSection(hourlyData: viewModel.hourlyData)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("통계")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: viewModel.isLoading ? "arrow.clockwise" : "arrow.clockwise")
                            .rotationEffect(viewModel.isLoading ? .degrees(360) : .zero)
                            .animation(
                                viewModel.isLoading
                                    ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                                    : .default,
                                value: viewModel.isLoading
                            )
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .onAppear {
            Task { await viewModel.refresh() }
        }
    }
}

// MARK: - Top 3 혼잡 구역

private struct TopZonesSection: View {
    let zones: [ZoneDensity]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "지금 가장 혼잡한 구역", systemImage: "flame.fill")

            if zones.isEmpty {
                Text("데이터 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ForEach(Array(zones.enumerated()), id: \.element.id) { rank, zone in
                    TopZoneRow(rank: rank + 1, zone: zone)
                }
            }
        }
    }
}

private struct TopZoneRow: View {
    let rank: Int
    let zone: ZoneDensity

    var body: some View {
        HStack(spacing: 14) {
            // 순위 뱃지
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Text("\(rank)")
                    .font(.subheadline.bold())
                    .foregroundStyle(rankColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(zone.zoneId)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text("\(zone.currentCount)명")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            DensityBadge(level: zone.densityLevel)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .orange
        case 2: return Color(UIColor.systemGray)
        default: return Color(UIColor.systemGray2)
        }
    }
}

// MARK: - 층별 바 차트

private struct FloorBarChartSection: View {
    let floorStats: [FloorStat]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "층별 평균 혼잡도", systemImage: "building.2")

            if floorStats.isEmpty {
                Text("데이터 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                Chart(floorStats) { stat in
                    BarMark(
                        x: .value("층", stat.floorLabel),
                        y: .value("평균 인원", stat.averageCount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        Text("\(Int(stat.averageCount))")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text("\(v)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
    }
}

// MARK: - 시간대별 라인 차트

private struct HourlyLineChartSection: View {
    let hourlyData: [HourlyDensity]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "오늘 시간대별 방문자", systemImage: "clock.fill")

            if hourlyData.isEmpty {
                Text("데이터 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                Chart(hourlyData) { data in
                    AreaMark(
                        x: .value("시간", data.hour),
                        y: .value("방문자", data.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.35), Color.accentColor.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("시간", data.hour),
                        y: .value("방문자", data.count)
                    )
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol(Circle().strokeBorder(lineWidth: 1.5))
                    .symbolSize(30)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 3)) { value in
                        AxisValueLabel {
                            if let hour = value.as(Int.self) {
                                Text("\(hour)시")
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text("\(v)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - 공용 섹션 헤더

private struct SectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class StatsTabViewModel {

    var zoneDensities: [ZoneDensity] = []
    var hourlyData: [HourlyDensity]  = []
    var isLoading: Bool = false

    private let densityService: DensityService
    private let imdfStore: IMDFStore

    init(densityService: DensityService, imdfStore: IMDFStore) {
        self.densityService = densityService
        self.imdfStore      = imdfStore
    }

    // MARK: - Computed

    var topZones: [ZoneDensity] {
        zoneDensities
            .sorted { $0.currentCount > $1.currentCount }
            .prefix(3)
            .map { $0 }
    }

    var floorStats: [FloorStat] {
        let grouped = Dictionary(grouping: zoneDensities) { $0.floorOrdinal }
        return grouped.map { ordinal, zones in
            let avg = Double(zones.map(\.currentCount).reduce(0, +)) / Double(max(zones.count, 1))
            let label = imdfStore.levels.first { $0.properties.ordinal == ordinal }?.displayName ?? "\(ordinal)F"
            return FloorStat(floorOrdinal: ordinal, floorLabel: label, averageCount: avg)
        }
        .sorted { $0.floorOrdinal < $1.floorOrdinal }
    }

    // MARK: - Actions

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        async let densityFetch = densityService.fetchCurrentDensity()
        async let hourlyFetch  = densityService.fetchHourlyDensity()

        do {
            let (zones, hourly) = try await (densityFetch, hourlyFetch)
            zoneDensities = zones
            hourlyData    = hourly
        } catch {
            // 에러는 조용히 무시 (이미 표시된 데이터 유지)
        }
    }
}

// MARK: - Supporting Types

struct FloorStat: Identifiable {
    let id = UUID()
    let floorOrdinal: Int
    let floorLabel: String
    let averageCount: Double
}
