import Foundation

struct SecurityConfig: Codable {
    var passwordHash:         String = ""
    var recoveryPasswordHash: String = ""
    var securityQuestion:     String = ""
    var securityAnswerHash:   String = ""
    var failedAttempts:       Int    = 0
    var isConfigured:         Bool   = false

    static let fileName = "security.json"

    static func load() -> SecurityConfig {
        guard let url  = fileURL(),
              let data = try? Data(contentsOf: url),
              let cfg  = try? JSONDecoder().decode(SecurityConfig.self, from: data)
        else { return SecurityConfig() }
        return cfg
    }

    func save() {
        guard let url  = SecurityConfig.fileURL(),
              let data = try? JSONEncoder().encode(self)
        else { return }
        try? data.write(to: url, options: .completeFileProtection)
    }

    mutating func incrementFailed() { failedAttempts += 1; save() }
    mutating func resetFailed()     { failedAttempts  = 0; save() }

    private static func fileURL() -> URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("_system")
            .appendingPathComponent(fileName)
    }

    static func ensureSystemDir() {
        guard let dir = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("_system")
        else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
}
