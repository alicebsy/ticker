import SwiftUI

/// PriceBadgeView: 등락률/변동값을 주식 앱처럼 배지로 보여주는 컴포넌트
struct PriceBadgeView: View {
    enum Size {
        case sm, md, lg

        var font: Font {
            switch self {
            case .sm: return .caption2
            case .md: return .caption
            case .lg: return .body
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .sm: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .md: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .lg: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .sm: return 10
            case .md: return 12
            case .lg: return 14
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .sm: return 6
            case .md: return 8
            case .lg: return 10
            }
        }
    }

    let value: Double
    var percentage: Bool = true
    var showIcon: Bool = true
    var size: Size = .md

    private var isPositive: Bool { value > 0 }
    private var isNeutral: Bool { value == 0 }

    private var symbolName: String {
        if isNeutral { return "minus" }
        return isPositive ? "arrow.up.right" : "arrow.down.right"
    }

    private var foreground: Color {
        if isNeutral { return .secondary }
        return isPositive ? .green : .red
    }

    private var background: Color {
        if isNeutral { return Color.secondary.opacity(0.15) }
        return (isPositive ? Color.green : Color.red).opacity(0.12)
    }

    private var formattedValue: String {
        // TS 버전: value.toFixed(2)
        let absString = String(format: "%.2f", value)
        let sign = isPositive ? "+" : ""
        let suffix = percentage ? "%" : ""
        return "\(sign)\(absString)\(suffix)"
    }

    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: symbolName)
                    .font(.system(size: size.iconSize, weight: .semibold))
            }

            Text(formattedValue)
                .font(size.font.weight(.semibold))
        }
        .foregroundStyle(foreground)
        .padding(size.padding)
        .background(
            RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                .fill(background)
        )
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if isNeutral { return "변동 없음 \(formattedValue)" }
        return isPositive ? "상승 \(formattedValue)" : "하락 \(formattedValue)"
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 10) {
        PriceBadgeView(value: 5.92, percentage: true, showIcon: true, size: .sm)
        PriceBadgeView(value: 1.21, percentage: true, showIcon: true, size: .md)
        PriceBadgeView(value: -2.44, percentage: true, showIcon: true, size: .lg)
        PriceBadgeView(value: 0.00, percentage: true, showIcon: true, size: .md)
        PriceBadgeView(value: 12.3456, percentage: false, showIcon: false, size: .md)
    }
    .padding()
    .frame(width: 320)
}
