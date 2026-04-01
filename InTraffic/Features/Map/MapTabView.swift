// MapTabView.swift
// InTraffic

import MapKit
import SwiftUI

struct MapTabView: View {

    @State private var viewModel: MapTabViewModel
    @State private var hourlyData: [HourlyDensity] = []
    @State private var mapCameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.014267, longitude: 129.325778),
            latitudinalMeters: 200,
            longitudinalMeters: 200
        )
    )

    private let mapBounds = MapCameraBounds(
        centerCoordinateBounds: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.014267, longitude: 129.325778),
            latitudinalMeters: 500,
            longitudinalMeters: 500
        ),
        minimumDistance: 10,
        maximumDistance: 600
    )

    init(
        imdfStore: IMDFStore,
        densityService: DensityService,
        eventUploader: EventUploader,
        locationManager: LocationManager
    ) {
        _viewModel = State(initialValue: MapTabViewModel(
            imdfStore: imdfStore,
            densityService: densityService,
            eventUploader: eventUploader,
            locationManager: locationManager
        ))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // MARK: Map
            Map(
                position: $mapCameraPosition,
                bounds: mapBounds,
                interactionModes: [.zoom, .pan, .rotate]
            ) {
                // 구조물 폴리곤 (색 없는 윤곽선 + 기본 구조색)
                ForEach(viewModel.polygons) { polygon in
                    MapPolygon(coordinates: polygon.coordinates)
                        .foregroundStyle(polygon.fillColor)
                        .stroke(polygon.strokeColor, lineWidth: polygon.lineWidth)
                }

                // 히트맵 포인트 (밀도 기반 색상 원)
                ForEach(viewModel.heatPoints) { point in
                    MapCircle(center: point.coordinate, radius: point.radius)
                        .foregroundStyle(point.densityLevel.color.opacity(point.opacity))
                }

                // 사용자 위치
                UserAnnotation()
                    .mapOverlayLevel(level: .aboveLabels)
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .mapControlVisibility(.hidden)
            .ignoresSafeArea()
            .onTapGesture { _ in
                viewModel.clearSelection()
            }

            // MARK: 좌상단 컨트롤
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    FloorPopoverButton(
                        floors: viewModel.allFloorLabels,
                        selectedIndex: viewModel.selectedFloorIndex,
                        onSelect: { viewModel.selectFloor(index: $0) }
                    )
                    Spacer()
                    Button {
                        viewModel.manualRefresh()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.isLoading ? "arrow.clockwise" : "clock")
                                .font(.caption)
                                .rotationEffect(viewModel.isLoading ? .degrees(360) : .zero)
                                .animation(
                                    viewModel.isLoading
                                        ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                                        : .default,
                                    value: viewModel.isLoading
                                )
                            Text("\(viewModel.refreshCountdown)s")
                                .font(.caption.monospacedDigit())
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    .foregroundStyle(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }

            // MARK: 하단 범례
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    DensityLegendView()
                    Spacer()
                }
                .padding(.bottom, 20)
            }
        }
        // MARK: Zone 상세 시트
        .sheet(item: Binding(
            get: { viewModel.selectedZone.map { SelectedZoneWrapper(zone: $0.zone, density: $0.density) } },
            set: { if $0 == nil { viewModel.clearSelection() } }
        )) { wrapper in
            ZoneDetailSheet(
                zone: wrapper.zone,
                density: wrapper.density,
                hourlyData: hourlyData,
                onDismiss: { viewModel.clearSelection() }
            )
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

// MARK: - Sheet용 Identifiable 래퍼

private struct SelectedZoneWrapper: Identifiable {
    let id = UUID()
    let zone: ZonePolygon
    let density: ZoneDensity?
}
