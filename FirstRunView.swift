import SwiftUI

struct FirstRunView: View {
    @EnvironmentObject var appState: AppState

    @State private var password        = ""
    @State private var passwordConfirm = ""
    @State private var recovery        = ""
    @State private var recoveryConfirm = ""
    @State private var question        = ""
    @State private var answer          = ""
    @State private var errorMsg        = ""
    @State private var showError       = false
    @State private var step            = 0 // 0=haslo, 1=odzyskiwanie, 2=pytanie

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 52))
                            .foregroundColor(.indigo)
                        Text("Konfiguracja")
                            .font(.title.bold())
                        Text("Skonfiguruj zabezpieczenia aplikacji")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Krok 1 – haslo
                    SectionCard(title: "Haslo glowne", icon: "key.fill", color: .indigo) {
                        SecureField("Haslo", text: $password)
                            .textFieldStyle(.roundedBorder)
                        SecureField("Powtorz haslo", text: $passwordConfirm)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Krok 2 – odzyskiwanie
                    SectionCard(title: "Haslo odzyskiwania", icon: "arrow.counterclockwise", color: .orange) {
                        Text("Uzywane gdy zapomnisz hasla glownego")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("Haslo odzyskiwania", text: $recovery)
                            .textFieldStyle(.roundedBorder)
                        SecureField("Powtorz odzyskiwania", text: $recoveryConfirm)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Krok 3 – pytanie
                    SectionCard(title: "Pytanie zabezpieczajace", icon: "questionmark.circle.fill", color: .green) {
                        TextField("Np. Imie pierwszego zwierzaka?", text: $question)
                            .textFieldStyle(.roundedBorder)
                        SecureField("Odpowiedz", text: $answer)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Przycisk
                    Button(action: finish) {
                        Label("Zapisz i uruchom", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert("Blad", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMsg)
            }
        }
    }

    private func finish() {
        guard !password.isEmpty                  else { err("Haslo nie moze byc puste.");          return }
        guard password == passwordConfirm        else { err("Hasla glowne nie sa identyczne.");     return }
        guard !recovery.isEmpty                  else { err("Haslo odzyskiwania nie moze byc puste."); return }
        guard recovery == recoveryConfirm        else { err("Hasla odzyskiwania nie sa identyczne."); return }
        guard password != recovery               else { err("Haslo glowne i odzyskiwania musza byc rozne."); return }
        guard !question.isEmpty                  else { err("Wpisz pytanie zabezpieczajace.");      return }
        guard !answer.isEmpty                    else { err("Wpisz odpowiedz.");                    return }

        appState.secConfig.passwordHash         = CryptoHelper.hashPassword(password)
        appState.secConfig.recoveryPasswordHash = CryptoHelper.hashPassword(recovery)
        appState.secConfig.securityQuestion     = question
        appState.secConfig.securityAnswerHash   = CryptoHelper.hashPassword(answer.trimmingCharacters(in: .whitespaces).lowercased())
        appState.secConfig.isConfigured         = true
        appState.secConfig.failedAttempts       = 0
        appState.secConfig.save()
        appState.isConfigured = true
    }

    private func err(_ msg: String) { errorMsg = msg; showError = true }
}

struct SectionCard<Content: View>: View {
    let title:   String
    let icon:    String
    let color:   Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(color)
            content()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}
