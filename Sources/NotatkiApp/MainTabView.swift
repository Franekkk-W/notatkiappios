import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            NotesListView(noteManager: appState.noteManager!)
                .tabItem {
                    Label("Notatki", systemImage: "note.text")
                }

            NavigationView {
                CalculatorView()
            }
            .tabItem {
                Label("Kalkulator", systemImage: "calculator")
            }

            SettingsView()
                .tabItem {
                    Label("Ustawienia", systemImage: "gear")
                }
        }
        .accentColor(.indigo)
    }
}
