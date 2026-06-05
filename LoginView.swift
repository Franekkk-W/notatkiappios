import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState

    @State private var password  = ""
    @State private var errorMsg  = ""
    @State private var showError = false
    @State private var showReset = false

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()

                // Logo
                VStack(spacing: 10) {
                    Image(systemName: "note.text")
                        .font(.system(size: 60))
                        .foregroundColor(.indigo)
                    Text("Notatki")
                        .font(.largeTitle.bold())
                    Text("Twoje notatki sa bezpieczne")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Pole hasla
                VStack(spacing: 12) {
                    SecureField("Wpisz haslo", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                        .submitLabel(.go)
                        .onSubmit(login)

                    // Licznik prob
                    if appState.secConfig.failedAttempts > 0 {
                        Text("Pozostalo prob: \(3 - appState.secConfig.failedAttempts)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 32)

                // Przyciski
                VStack(spacing: 12) {
                    Button(action: login) {
                        Label("Zaloguj", systemImage: "arrow.right.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }

                    Button(action: { showReset = true }) {
                        Text("Zapomnialem hasla")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .navigationBarHidden(true)
            .alert("Blad", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMsg)
            }
            .sheet(isPresented: $showReset) {
                ResetPasswordView()
                    .environmentObject(appState)
            }
        }
    }

    private func login() {
        if appState.secConfig.failedAttempts >= 3 {
            errorMsg  = "Przekroczono limit prob. Zamknij i otworz aplikacje ponownie."
            showError = true
            return
        }

        if CryptoHelper.verifyPassword(password, hash: appState.secConfig.passwordHash) {
            appState.login(password: password)
        } else {
            appState.secConfig.incrementFailed()
            let remaining = 3 - appState.secConfig.failedAttempts
            if remaining <= 0 {
                errorMsg = "Przekroczono limit blednych prob. Aplikacja zostanie zamknieta."
                showError = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    exit(0)
                }
            } else {
                errorMsg  = "Bledne haslo! Pozostalo prob: \(remaining)"
                showError = true
                password  = ""
            }
        }
    }
}
