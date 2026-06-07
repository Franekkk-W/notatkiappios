import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var isLoggedIn:   Bool           = false
    @Published var isConfigured: Bool           = false
    @Published var password:     String         = ""
    @Published var noteManager:  NoteManager?   = nil
    @Published var secConfig:    SecurityConfig = SecurityConfig.load()

    init() {
        SecurityConfig.ensureSystemDir()
        secConfig    = SecurityConfig.load()
        isConfigured = secConfig.isConfigured
    }

    func login(password: String) {
        self.password    = password
        self.noteManager = NoteManager(password: password)
        self.isLoggedIn  = true
        secConfig.resetFailed()
    }

    func logout() {
        password    = ""
        noteManager = nil
        isLoggedIn  = false
    }
}
