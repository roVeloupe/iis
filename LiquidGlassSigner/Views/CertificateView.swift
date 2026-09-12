import SwiftUI
import UniformTypeIdentifiers

struct CertificateView: View {
    @State private var showImporter = false
    @State private var password = ""
    @State private var certificates: [CertificateInfo] = []
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AuroraBackground()
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("导入 .p12 证书")
                            .font(.headline)
                            .foregroundStyle(.white)

                        SecureField("证书密码", text: $password)
                            .padding(14)
                            .background(.white.opacity(0.08),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1))

                        Button {
                            showImporter = true
                        } label: {
                            Label("选择证书文件", systemImage: "folder.badge.plus")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue.opacity(0.8))
                    }
                    .padding(20)
                    .glassCard()

                    if !certificates.isEmpty {
                        SectionTitle(text: "证书信息")
                        ForEach(certificates) { cert in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(cert.commonName)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Spacer()
                                    BadgeView(text: cert.isExpired ? "已过期" : "有效",
                                              color: cert.isExpired ? .red : .green)
                                }
                                Divider().overlay(.white.opacity(0.15))
                                HStack {
                                    Text("证书状态").foregroundStyle(.white.opacity(0.55))
                                    Spacer()
                                    Text(cert.isExpired ? "已过期" : "有效期正常")
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                                .font(.subheadline)
                            }
                            .padding(18)
                            .glassCard(cornerRadius: 20)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("证书管理")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.pkcs12]) { result in
            handleImport(result)
        }
        .alert("导入失败",
               isPresented: Binding(get: { errorMessage != nil },
                                    set: { if !$0 { errorMessage = nil } })) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
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
        do {
            let infos = try CertificateService.importP12(data: data, password: password)
            certificates = infos
            if infos.isEmpty {
                errorMessage = "证书中没有可导入的身份"
            }
        } catch let error as SigningError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "导入失败"
        }
    }
}
