import Foundation
import Security

let p12Data = try! Data(contentsOf: URL(fileURLWithPath: NSHomeDirectory() + "/Downloads/Certificados.p12"))
let options: [String: Any] = [kSecImportExportPassphrase as String: "P!ki3536"]
var items: CFArray?
let status = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &items)

if status == errSecSuccess, let itemsArray = items as? [[String: Any]] {
    for item in itemsArray {
        if let cert = item[kSecImportItemCertChain as String] as? [SecCertificate], let first = cert.first {
            var summary: CFString?
            summary = SecCertificateCopySubjectSummary(first)
            print("Certificate: \(summary ?? "" as CFString)")
        }
    }
} else {
    print("Failed to import p12: \(status)")
}
