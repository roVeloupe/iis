import SwiftUI
import UniformTypeIdentifiers

struct ProfileView: View {
    @State private var showImporter = false
    @State private var profile: ProvisionProfile?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AuroraBackground()
            ScrollView {
                VStack(spacing: 18) {
                    Button {
                        showImporter = true
                    } label: {
                        Label("选择 .mobileprovision", systemImage: "doc.badge.plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple.opacity(0.8))

                    if let profile {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(profile.name)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Spacer()
                                BadgeView(text: profile.isExpired ? "已过期" : "有效",
                                          color: profile.isExpired ? .red : .green)
                            }
                            Divider().overlay(.white.opacity(0.15))
                            row("UUID", profile.uuid)
                            row("Team ID", profile.teamID)
                            row("设备数量", "\(profile.deviceCount)")
                            if let exp = profile.expiration {
                                row("过期时间", exp.formatted(date: .abbreviated, time: .shortened))
                            }
                        }
                        .padding(18)
                        .glassCard()
                    } else {
                        Text("尚未解析描述文件")
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .glassCard()
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("描述文件")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data]) { result in
            handleImport(result)
        }
        .alert("解析失败",
               isPresented: Binding(get: { errorMessage != nil },
                                    set: { if !$0 { errorMessage = nil } })) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title).foregroundStyle(.white.opacity(0.55))
            Spacer()
            Text(value)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "无法访问所选文件"
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url) else {
            errorMessage = "文件读取失败"
            return
        }
        guard let parsed = ProfileService.parse(data) else {
            errorMessage = "不是有效的描述文件"
            return
        }
        profile = parsed
    }
}
