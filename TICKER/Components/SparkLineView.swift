import SwiftUI

/// SparklineView: 주가 미니 차트(스파크라인)
/// - data: 값 배열 (2개 이상 필요)
/// - lineWidth: 선 두께
/// - fixedColor: 색 강제 지정(없으면 상승/하락으로 자동)
struct SparklineView: View {
    let data: [Double]
    var lineWidth: CGFloat = 1.5
    var fixedColor: Color? = nil
    var showGradient: Bool = false

    // TS 버전: isPositive = last >= first
    private var isPositive: Bool {
        guard let first = data.first, let last = data.last else { return true }
        return last >= first
    }

    private var strokeColor: Color {
        if let fixedColor { return fixedColor }
        return isPositive ? .green : .red
    }

    var body: some View {
        // TS 버전: data.length < 2 return null
        Group {
            if data.count < 2 {
                EmptyView()
            } else {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    let minV = data.min() ?? 0
                    let maxV = data.max() ?? 1
                    let range = (maxV - minV) == 0 ? 1 : (maxV - minV)

                    Path { path in
                        for i in data.indices {
                            let x = CGFloat(i) / CGFloat(data.count - 1) * w
                            // TS 버전: y = height - ((value - min) / range) * height
                            let normalized = (data[i] - minV) / range
                            let y = h - CGFloat(normalized) * h

                            if i == data.startIndex {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        strokeColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 12) {
            SparklineView(data: [1, 2, 3, 2.8, 3.4, 4.2, 4.1])
                .frame(width: 90, height: 24)

            SparklineView(data: [4.2, 4.0, 3.7, 3.2, 2.9, 2.6, 2.5])
                .frame(width: 90, height: 24)
        }

        SparklineView(data: [1, 1, 1, 1, 1], fixedColor: .secondary)
            .frame(width: 180, height: 30)

        SparklineView(data: [1]) // 데이터 부족 → 아무것도 안 나옴
            .frame(width: 180, height: 30)
    }
    .padding()
    .frame(width: 320)
}
