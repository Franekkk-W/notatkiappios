import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var recovery        = ""
    @State private var answer          = ""
    @State private var newPassword     = ""
    @State private var newConfirm      = ""
    @State private var errorMsg        = ""
    @State private var showError       = false
    @State private var showSuccess     = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Image(systemName: "key.horizontal.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.orange)
                        Text("Reset hasla")
                            .font(.title.bold())
                    }
                    .padding(.top, 20)

                    SectionCard(title: "Haslo odzyskiwania", icon: "arrow.counterclockwise", color: .orange) {
                        SecureField("Wpisz haslo odzyskiwania", text: $recovery)
                            .textFieldStyle(.roundedBorder)
                    }

                    SectionCard(title: appState.secConfig.securityQuestion, icon: "questionmark.circle.fill", color: .green) {
                        SecureField("Twoja odpowiedz", text: $answer)
                            .textFieldStyle(.roundedBorder)
                    }

                    SectionCard(title: "Nowe haslo", icon: "lock.fill", color: .indigo) {
                        SecureField("Nowe haslo", text: $newPassword)
                            .textFieldStyle(.roundedBorder)
                        SecureField("Powtorz nowe haslo", text: $newConfirm)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(action: reset) {
                        Label("Zresetuj haslo", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Reset hasla")
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
            } message: { Text("Haslo zostalo zmienione. Mozesz sie zalogowac.") }
        }
    }

    private func reset() {
        guard CryptoHelper.verifyPassword(recovery, hash: appState.secConfig.recoveryPasswordHash)
        else { err("Nieprawidlowe haslo odzyskiwania."); return }

        let ansHash = CryptoHelper.hashPassword(answer.trimmingCharacters(in: .whitespaces).lowercased())
        guard ansHash == appState.secConfig.securityAnswerHash
        else { err("Nieprawidlowa odpowiedz na pytanie."); return }

        guard !newPassword.isEmpty            else { err("Nowe haslo nie moze byc puste."); return }
        guard newPassword == newConfirm       else { err("Hasla nie sa identyczne."); return }

        appState.secConfig.passwordHash   = CryptoHelper.hashPassword(newPassword)
        appState.secConfig.failedAttempts = 0
        appState.secConfig.save()
        showSuccess = true
    }

    private func err(_ msg: String) { errorMsg = msg; showError = true }
}
