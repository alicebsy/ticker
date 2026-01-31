import SwiftUI
import AppKit

// MARK: - App Theme
struct AppTheme {
    // Primary Colors
    static let gain = Color.green
    static let loss = Color.red
    static let neon = Color(red: 0.2, green: 1.0, blue: 0.6)
    static let casino = Color(red: 1.0, green: 0.4, blue: 0.8)

    // Dynamic Colors Helpers
    private static func dynamicColor(dark: NSColor, light: NSColor) -> Color {
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        }))
    }

    // Background Colors
    static var background: Color {
        dynamicColor(
            dark: NSColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0),      // #121214
            light: NSColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)      // #F5F5F7
        )
    }
    
    static var cardBackground: Color {
        dynamicColor(
            dark: NSColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.0),      // #1C1C21
            light: NSColor(white: 1.0, alpha: 1.0)                              // #FFFFFF
        )
    }
    
    static var cardBackgroundLight: Color {
        dynamicColor(
            dark: NSColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1.0),      // #262628
            light: NSColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0)      // #F0F0F5
        )
    }
    
    static var sidebarBackground: Color {
        dynamicColor(
            dark: NSColor(red: 0.09, green: 0.09, blue: 0.10, alpha: 1.0),      // #171719
            light: NSColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)      // #F2F2F7
        )
    }
    
    static var border: Color {
        dynamicColor(
            dark: NSColor(white: 1.0, alpha: 0.08),
            light: NSColor(white: 0.0, alpha: 0.08)
        )
    }

    // Text Colors
    static var primaryText: Color {
        dynamicColor(
            dark: NSColor.white,
            light: NSColor.black
        )
    }
    
    static var secondaryText: Color {
        dynamicColor(
            dark: NSColor.white.withAlphaComponent(0.55),
            light: NSColor.black.withAlphaComponent(0.55)
        )
    }
    
    static var tertiaryText: Color {
        dynamicColor(
            dark: NSColor.white.withAlphaComponent(0.35),
            light: NSColor.black.withAlphaComponent(0.35)
        )
    }
}

// MARK: - Custom View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

struct GlassCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func glassCardStyle() -> some View {
        modifier(GlassCardStyle())
    }
}

// MARK: - Price Change Badge
struct PriceChangeBadge: View {
    let change: Double
    var showPercentage: Bool = true

    private var isPositive: Bool { change >= 0 }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                .font(.system(size: 8))

            if showPercentage {
                Text(String(format: "%+.1f%%", change))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
            }
        }
        .foregroundStyle(isPositive ? AppTheme.gain : AppTheme.loss)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            (isPositive ? AppTheme.gain : AppTheme.loss).opacity(0.15)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Sparkline View
struct SparklineView: View {
    let data: [Double]
    var color: Color = .blue
    var showGradient: Bool = true

    private var normalizedData: [Double] {
        guard let minVal = data.min(), let maxVal = data.max(), maxVal != minVal else {
            return data.map { _ in 0.5 }
        }
        return data.map { ($0 - minVal) / (maxVal - minVal) }
    }

    private var isPositive: Bool {
        guard let first = data.first, let last = data.last else { return true }
        return last >= first
    }

    private var lineColor: Color {
        isPositive ? AppTheme.gain : AppTheme.loss
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let stepX = width / CGFloat(max(normalizedData.count - 1, 1))

            ZStack {
                // Gradient fill
                if showGradient {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: height))

                        for (index, value) in normalizedData.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - (CGFloat(value) * height)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }

                        path.addLine(to: CGPoint(x: width, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [lineColor.opacity(0.3), lineColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                // Line
                Path { path in
                    for (index, value) in normalizedData.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - (CGFloat(value) * height)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

// MARK: - Avatar View
struct AvatarView: View {
    let name: String
    let color: Color
    var size: CGFloat = 40

    private var initials: String {
        String(name.prefix(1))
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.gradient)

            Text(initials)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let iconColor: Color

    init(title: String, value: String, subtitle: String? = nil, icon: String, iconColor: Color = .blue) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.primaryText)
        }
    }
}
