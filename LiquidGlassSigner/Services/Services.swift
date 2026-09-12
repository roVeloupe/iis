import Foundation
import Security

enum SigningError: LocalizedError {
    case badPassword
    case invalidFile
    case empty

    var errorDescription: String? {
        switch self {
        case .badPassword: return "证书密码错误或证书格式不受支持"
        case .invalidFile: return "文件无法读取"
        case .empty: return "证书中没有可导入的身份"
        }
    }
}

/// 证书与描述文件解析服务
enum CertificateService {
    /// 导入 .p12 并返回其中包含的证书列表
    static func importP12(data: Data, password: String) throws -> [CertificateInfo] {
        let options: [String: Any] = [kSecImportExportPassphrase as String: password]
        var rawItems: CFArray?
        let status = SecPKCS12Import(data as CFData, options as CFDictionary, &rawItems)
        guard status == errSecSuccess else { throw SigningError.badPassword }
        guard let items = rawItems as? [[String: Any]], !items.isEmpty else { throw SigningError.empty }

        return items.compactMap { item in
            guard let identity = item[kSecImportItemIdentity as String] as? SecIdentity else { return nil }
            var certRef: SecCertificate?
            guard SecIdentityCopyCertificate(identity, &certRef) == errSecSuccess, let cert = certRef else { return nil }
            return CertificateInfo(
                commonName: SecCertificateCopySubjectSummary(cert) as String? ?? "未知证书",
                notBefore: validityDate(cert, kSecOIDX509V1ValidityNotBefore),
                notAfter: validityDate(cert, kSecOIDX509V1ValidityNotAfter)
            )
        }
    }

    private static func validityDate(_ cert: SecCertificate, _ oid: CFString) -> Date {
        guard let values = SecCertificateCopyValues(cert, [oid] as CFArray, nil) as? [CFString: Any],
              let dict = values[oid] as? [CFString: Any],
              let raw = dict[kSecPropertyKeyValue as CFString] else { return .distantPast }
        if let date = raw as? Date { return date }
        if let num = raw as? NSNumber { return Date(timeIntervalSince1970: num.doubleValue) }
        return .distantPast
    }
}

enum ProfileService {
    /// 解析 .mobileprovision（CMS 签名的 plist，plist 位于文件末尾）
    static func parse(_ data: Data) -> ProvisionProfile? {
        guard let range = data.range(of: Data("<?xml".utf8)) else { return nil }
        let plistData = data.subdata(in: range.lowerBound..<data.endIndex)
        guard let dict = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else { return nil }

        let expiration = dict["ExpirationDate"] as? Date
        return ProvisionProfile(
            name: dict["Name"] as? String ?? "未知描述文件",
            uuid: dict["UUID"] as? String ?? "—",
            teamID: (dict["TeamIdentifier"] as? [String])?.first ?? "—",
            expiration: expiration,
            deviceCount: (dict["ProvisionedDevices"] as? [String])?.count ?? 0
        )
    }
}
