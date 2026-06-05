import SwiftUI

struct NotesListView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var noteManager: NoteManager

    @State private var showNewNote    = false
    @State private var newNoteName    = ""
    @State private var errorMsg       = ""
    @State private var showError      = false
    @State private var selectedNote:  String? = nil

    var body: some View {
        NavigationView {
            Group {
                if noteManager.notes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "note.text.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Brak notatek")
                            .font(.title2.bold())
                        Text("Kliknij + aby dodac pierwsza notatke")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(noteManager.notes) { note in
                            NavigationLink(destination:
                                NoteDetailView(noteManager: noteManager, noteName: note.name)
                            ) {
                                HStack(spacing: 14) {
                                    Image(systemName: "note.text")
                                        .font(.title2)
                                        .foregroundColor(.indigo)
                                        .frame(width: 36, height: 36)
                                        .background(Color.indigo.opacity(0.1))
                                        .cornerRadius(8)
                                    Text(note.name)
                                        .font(.body.weight(.medium))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteNotes)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Notatki")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewNote = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .alert("Nowa notatka", isPresented: $showNewNote) {
                TextField("Nazwa notatki", text: $newNoteName)
                Button("Dodaj", action: createNote)
                Button("Anuluj", role: .cancel) { newNoteName = "" }
            }
            .alert("Blad", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMsg) }
        }
    }

    private func createNote() {
        let name = newNoteName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        do {
            try noteManager.createNote(name: name)
            newNoteName = ""
        } catch {
            errorMsg  = "Notatka o tej nazwie juz istnieje."
            showError = true
        }
    }

    private func deleteNotes(at offsets: IndexSet) {
        for i in offsets {
            try? noteManager.deleteNote(name: noteManager.notes[i].name)
        }
    }
}
