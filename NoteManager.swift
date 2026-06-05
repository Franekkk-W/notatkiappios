import Foundation
import UIKit

struct Note: Identifiable {
    let id   = UUID()
    var name: String
}

class NoteManager: ObservableObject {
    @Published var notes: [Note] = []

    private let password: String
    private let root: URL

    init(password: String) {
        self.password = password
        self.root     = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        loadNotes()
    }

    // MARK: – Lista notatek
    func loadNotes() {
        guard let dirs = try? FileManager.default.contentsOfDirectory(
            at: root, includingPropertiesForKeys: [.isDirectoryKey]) else { return }
        notes = dirs
            .filter { url in
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
                return isDir.boolValue && url.lastPathComponent != "_system"
            }
            .map { Note(name: $0.lastPathComponent) }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    // MARK: – Sciezki
    private func noteDir(_ name: String)   -> URL { root.appendingPathComponent(name) }
    private func imagePath(_ name: String) -> URL { noteDir(name).appendingPathComponent("image.enc") }
    private func textPath(_ name: String)  -> URL { noteDir(name).appendingPathComponent("text.enc") }

    func noteExists(_ name: String) -> Bool {
        FileManager.default.fileExists(atPath: noteDir(name).path)
    }

    // MARK: – Tworzenie
    func createNote(name: String) throws {
        if noteExists(name) { throw NoteError.alreadyExists }
        try FileManager.default.createDirectory(at: noteDir(name), withIntermediateDirectories: true)
        loadNotes()
    }

    // MARK: – Zapis (szyfrowany)
    func saveNote(name: String, image: UIImage, text: String) throws {
        let dir = noteDir(name)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        if let imgData = image.pngData() {
            let encrypted = try CryptoHelper.encrypt(imgData, password: password)
            try encrypted.write(to: imagePath(name), options: .completeFileProtection)
        }

        let encText = try CryptoHelper.encryptString(text, password: password)
        try encText.write(to: textPath(name), atomically: true, encoding: .utf8)
    }

    // MARK: – Odczyt (deszyfrowany)
    func loadNote(name: String) -> (image: UIImage?, text: String) {
        var image: UIImage? = nil
        var text            = ""

        if let encData = try? Data(contentsOf: imagePath(name)),
           let plain   = try? CryptoHelper.decrypt(encData, password: password) {
            image = UIImage(data: plain)
        }

        if let encText = try? String(contentsOf: textPath(name), encoding: .utf8),
           let plain   = try? CryptoHelper.decryptString(encText, password: password) {
            text = plain
        }

        return (image, text)
    }

    // MARK: – Usuniecie
    func deleteNote(name: String) throws {
        try FileManager.default.removeItem(at: noteDir(name))
        loadNotes()
    }

    // MARK: – Reszyfrowanie po zmianie hasla
    func reEncryptAll(oldPassword: String, newPassword: String) throws {
        for note in notes {
            if let encData = try? Data(contentsOf: imagePath(note.name)),
               let plain   = try? CryptoHelper.decrypt(encData, password: oldPassword) {
                let newEnc = try CryptoHelper.encrypt(plain, password: newPassword)
                try newEnc.write(to: imagePath(note.name), options: .completeFileProtection)
            }
            if let encText = try? String(contentsOf: textPath(note.name), encoding: .utf8),
               let plain   = try? CryptoHelper.decryptString(encText, password: oldPassword) {
                let newEnc = try CryptoHelper.encryptString(plain, password: newPassword)
                try newEnc.write(to: textPath(note.name), atomically: true, encoding: .utf8)
            }
        }
    }

    enum NoteError: Error {
        case alreadyExists
    }
}
