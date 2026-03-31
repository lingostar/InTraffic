// FloorPopoverButton.swift
// InTraffic
// 지도 좌상단 층 선택 팝오버 버튼

import SwiftUI

struct FloorPopoverButton: View {
    let floors: [String]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "building.2.fill")
                    .font(.caption)
                Text(floors.indices.contains(selectedIndex) ? floors[selectedIndex] : "-")
                    .font(.subheadline.bold())
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .popover(isPresented: $isPresented, arrowEdge: .top) {
            FloorPickerList(
                floors: floors,
                selectedIndex: selectedIndex,
                onSelect: { index in
                    onSelect(index)
                    isPresented = false
                }
            )
            .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - 팝오버 내부 목록

private struct FloorPickerList: View {
    let floors: [String]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("층 선택")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

            Divider()

            ForEach(floors.indices, id: \.self) { index in
                Button {
                    onSelect(index)
                } label: {
                    HStack {
                        Text(floors[index])
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        if index == selectedIndex {
                            Image(systemName: "checkmark")
                                .font(.subheadline.bold())
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        index == selectedIndex
                            ? Color.blue.opacity(0.08)
                            : Color.clear
                    )
                }
                .buttonStyle(.plain)

                if index < floors.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .frame(minWidth: 160)
    }
}
