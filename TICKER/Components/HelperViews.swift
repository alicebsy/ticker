import SwiftUI

// MARK: - PriceChangeBadge (wrapper around PriceBadgeView)
/// Views에서 PriceChangeBadge(change:) 형태로 사용됨
struct PriceChangeBadge: View {
    let change: Double

    var body: some View {
        PriceBadgeView(value: change, percentage: true, showIcon: true, size: .sm)
    }
}

// MARK: - AvatarView (name/color/size variant used in Views)
/// Views에서 AvatarView(name:, color:, size:) 형태로 사용됨
struct AvatarView: View {
    let name: String
    var color: Color = .blue
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(color.gradient)
                .frame(width: size, height: size)

            Text(String(name.prefix(1)))
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - StatCard
struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String = ""
    var icon: String = ""
    var iconColor: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(iconColor)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.title3.weight(.bold))

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - CardStyle ViewModifier
struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyleModifier())
    }
}
