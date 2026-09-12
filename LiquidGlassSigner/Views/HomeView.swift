import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        HeroCard()

                        SectionTitle(text: "签名工具")

                        NavigationLink {
                            CertificateView()
                        } label: {
                            FeatureCard(icon: "lock.shield.fill",
                                        title: "证书管理",
                                        subtitle: "导入 .p12 证书，查看身份与有效期",
                                        accent: .blue)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ProfileView()
                        } label: {
                            FeatureCard(icon: "doc.text.fill",
                                        title: "描述文件",
                                        subtitle: "解析 .mobileprovision，查看设备与过期时间",
                                        accent: .purple)
                        }
                        .buttonStyle(.plain)

                        Text("iOS 26-27 · Liquid Glass · Swift 构建")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.35))
                            .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 26)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Liquid Glass Signer")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

struct HeroCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("iOS 26 · 27  LIQUID GLASS")
                .font(.caption.bold())
                .tracking(1.6)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.white.opacity(0.12), in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.3), lineWidth: 1))

            Text("Liquid Glass Signer")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Swift + SwiftUI 构建的 iOS 26-27 签名工具，由 GitHub Actions 自动构建出 IPA。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 22)
        .glassCard()
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(accent.opacity(0.35),
                            in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .strokeBorder(.white.opacity(0.28), lineWidth: 1))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.bold())
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(18)
        .glassCard(cornerRadius: 22)
    }
}
