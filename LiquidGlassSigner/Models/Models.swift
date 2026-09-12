import Foundation

/// 从 .p12 中解析出的证书信息
struct CertificateInfo: Identifiable {
    let id = UUID()
    let commonName: String
    let notBefore: Date
    let notAfter: Date

    var isExpired: Bool { notAfter < Date() }
}

/// 从 .mobileprovision 中解析出的描述文件信息
struct ProvisionProfile: Identifiable {
    let id = UUID()
    let name: String
    let uuid: String
    let teamID: String
    let expiration: Date?
    let deviceCount: Int

    var isExpired: Bool { expiration.map { $0 < Date() } ?? false }
}
