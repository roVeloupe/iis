import SwiftUI

/// 极光渐变背景（Liquid Glass 风格底层）
struct AuroraBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.05, blue: 0.12)
            RadialGradient(colors: [Color.blue.opacity(0.5), .clear],
                           center: .topTrailing, startRadius: 20, endRadius: 420)
                .blur(radius: 30)
            RadialGradient(colors: [Color.purple.opacity(0.45), .clear],
                           center: .bottomLeading, startRadius: 20, endRadius: 460)
                .blur(radius: 30)
            RadialGradient(colors: [Color.cyan.opacity(0.35), .clear],
                           center: .center, startRadius: 20, endRadius: 520)
                .blur(radius: 40)
        }
        .ignoresSafeArea()
    }
}

/// 液态玻璃卡片：毛玻璃 + 高光 + 描边 + 阴影
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.02)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 22, x: 0, y: 14)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 26) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

struct SectionTitle: View {
    let text: String

    var body: some View {
        HStack {
            Text(text)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

struct BadgeView: View {
    let text: String
    var color: Color = .blue

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.25), in: Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.5), lineWidth: 1))
            .foregroundStyle(.white)
    }
}
