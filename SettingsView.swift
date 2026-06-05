import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    @State private var showChangePassword = false
    @State private var showLogoutConfirm  = false

    var body: some View {
        NavigationView {
            List {
                Section("Konto") {
                    Button(action: { showChangePassword = true }) {
                        Label("Zmien haslo", systemImage: "key.fill")
                            .foregroundColor(.primary)
                    }

                    Button(action: { showLogoutConfirm = true }) {
                        Label("Wyloguj", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }

                Section("Bezpieczenstwo") {
                    HStack {
                        Label("Szyfrowanie", systemImage: "lock.shield.fill")
                        Spacer()
                        Text("AES-256")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Pytanie zabezpieczajace", systemImage: "questionmark.shield.fill")
                        Spacer()
                        Text("Ustawione")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                Section("Aplikacja") {
                    HStack {
                        Label("Wersja", systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Ustawienia")
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
                    .environmentObject(appState)
            }
            .confirmationDialog("Czy na pewno chcesz sie wylogowac?",
                isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Wyloguj", role: .destructive) { appState.logout() }
                Button("Anuluj", role: .cancel) {}
            }
        }
    }
}

struct ChangePasswordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var oldPassword  = ""
    @State private var newPassword  = ""
    @State private var newConfirm   = ""
    @State private var errorMsg     = ""
    @State private var showError    = false
    @State private var showSuccess  = false
    @State private var isLoading    = false

    var body: some View {
        NavigationView {
            Form {
                Section("Obecne haslo") {
                    SecureField("Obecne haslo", text: $oldPassword)
                }

                Section("Nowe haslo") {
                    SecureField("Nowe haslo", text: $newPassword)
                    SecureField("Powtorz nowe haslo", text: $newConfirm)
                }

                Section {
                    Button(action: change) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Zmien haslo")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .foregroundColor(.indigo)
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Zmien haslo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
            }
            .alert("Blad", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMsg) }
            .alert("Sukces", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: { Text("Haslo zostalo zmienione!") }
        }
    }

    private func change() {
        guard CryptoHelper.verifyPassword(oldPassword, hash: appState.secConfig.passwordHash)
        else { err("Obecne haslo jest nieprawidlowe."); return }
        guard !newPassword.isEmpty         else { err("Nowe haslo nie moze byc puste."); return }
        guard newPassword == newConfirm    else { err("Hasla nie sa identyczne."); return }
        guard newPassword != oldPassword   else { err("Nowe haslo musi byc inne niz stare."); return }

        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try appState.noteManager?.reEncryptAll(oldPassword: oldPassword, newPassword: newPassword)
                appState.secConfig.passwordHash = CryptoHelper.hashPassword(newPassword)
                appState.secConfig.save()
                appState.password = newPassword

                DispatchQueue.main.async {
                    isLoading   = false
                    showSuccess = true
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    err("Blad reszyfrowania: \(error.localizedDescription)")
                }
            }
        }
    }

    private func err(_ msg: String) { errorMsg = msg; showError = true }
}
