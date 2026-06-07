import Foundation
import CryptoKit

struct CryptoHelper {

    // MARK: – Haszowanie hasla
    static func hashPassword(_ password: String) -> String {
        let input = (password + "NP_SALT_2026").data(using: .utf8)!
        let hash  = SHA256.hash(data: input)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    static func verifyPassword(_ password: String, hash: String) -> Bool {
        hashPassword(password) == hash
    }

    // MARK: – AES-256-GCM szyfrowanie
    static func encrypt(_ data: Data, password: String) throws -> Data {
        let key       = deriveKey(from: password)
        let symKey    = SymmetricKey(data: key)
        let sealed    = try AES.GCM.seal(data, using: symKey)
        guard let combined = sealed.combined else {
            throw CryptoError.encryptionFailed
        }
        return combined
    }

    static func decrypt(_ data: Data, password: String) throws -> Data {
        let key    = deriveKey(from: password)
        let symKey = SymmetricKey(data: key)
        let box    = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(box, using: symKey)
    }

    static func encryptString(_ text: String, password: String) throws -> String {
        let data      = text.data(using: .utf8)!
        let encrypted = try encrypt(data, password: password)
        return encrypted.base64EncodedString()
    }

    static func decryptString(_ base64: String, password: String) throws -> String {
        guard let data = Data(base64Encoded: base64) else {
            throw CryptoError.invalidData
        }
        let plain = try decrypt(data, password: password)
        return String(data: plain, encoding: .utf8) ?? ""
    }

    // MARK: – Derywacja klucza PBKDF2
    private static func deriveKey(from password: String) -> Data {
        let passwordData = password.data(using: .utf8)!
        let salt         = "NP_PBKDF2_SALT_2026".data(using: .utf8)!
        var derivedKey   = Data(repeating: 0, count: 32)
        derivedKey.withUnsafeMutableBytes { derivedPtr in
            passwordData.withUnsafeBytes { passPtr in
                salt.withUnsafeBytes { saltPtr in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passPtr.baseAddress, passwordData.count,
                        saltPtr.baseAddress, salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        300_000,
                        derivedPtr.baseAddress, 32
                    )
                }
            }
        }
        return derivedKey
    }

    enum CryptoError: Error {
        case encryptionFailed
        case invalidData
    }
}
