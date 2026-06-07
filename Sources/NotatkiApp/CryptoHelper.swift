import Foundation
import CryptoKit

struct CryptoHelper {

    // MARK: – Haszowanie hasla (SHA-256)
    static func hashPassword(_ password: String) -> String {
        let input = (password + "NP_SALT_2026").data(using: .utf8)!
        let hash  = SHA256.hash(data: input)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    static func verifyPassword(_ password: String, hash: String) -> Bool {
        hashPassword(password) == hash
    }

    // MARK: – Derywacja klucza AES z hasla (HKDF zamiast PBKDF2)
    private static func deriveKey(from password: String) -> SymmetricKey {
        let passwordData = password.data(using: .utf8)!
        let salt = "NP_HKDF_SALT_2026".data(using: .utf8)!
        let info = "NotatkiApp_AES_KEY".data(using: .utf8)!

        // Uzywamy HKDF z SHA256 – dostepne w CryptoKit bez zadnych dodatkowych importow
        let inputKey = SymmetricKey(data: SHA256.hash(data: passwordData + salt))
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKey,
            salt: salt,
            info: info,
            outputByteCount: 32
        )
    }

    // MARK: – AES-256-GCM szyfrowanie
    static func encrypt(_ data: Data, password: String) throws -> Data {
        let key    = deriveKey(from: password)
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else {
            throw CryptoError.encryptionFailed
        }
        return combined
    }

    static func decrypt(_ data: Data, password: String) throws -> Data {
        let key = deriveKey(from: password)
        let box = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(box, using: key)
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

    enum CryptoError: Error {
        case encryptionFailed
        case invalidData
    }
}

// Operator do laczenia Data
private func + (lhs: Data, rhs: Data) -> Data {
    var result = lhs
    result.append(rhs)
    return result
}
