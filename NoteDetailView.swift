import SwiftUI

struct NoteDetailView: View {
    @ObservedObject var noteManager: NoteManager
    let noteName: String

    @State private var image:      UIImage? = nil
    @State private var text:       String  = ""
    @State private var showPaint:  Bool    = false
    @State private var showSaved:  Bool    = false
    @State private var errorMsg:   String  = ""
    @State private var showError:  Bool    = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Podglad rysunku
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemBackground))
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)

                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .cornerRadius(14)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "pencil.and.outline")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text("Brak rysunku")
                                .foregroundColor(.secondary)
                        }
                    }

                    // Przycisk edycji rysunku
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { showPaint = true }) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.indigo)
                                    .background(Color.white.clipShape(Circle()))
                            }
                            .padding(10)
                        }
                        Spacer()
                    }
                }

                // Tekst notatki
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tresc notatki", systemImage: "text.alignleft")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)

                    TextEditor(text: $text)
                        .frame(minHeight: 160)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .font(.body)
                }

                // Przycisk zapisu
                Button(action: save) {
                    HStack {
                        if showSaved {
                            Label("Zapisano!", systemImage: "checkmark.circle.fill")
                        } else {
                            Label("Zapisz notatke", systemImage: "square.and.arrow.down.fill")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(showSaved ? Color.green : Color.indigo)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .animation(.easeInOut(duration: 0.3), value: showSaved)
                }
            }
            .padding(16)
        }
        .navigationTitle(noteName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadNote)
        .sheet(isPresented: $showPaint) {
            NavigationView {
                PaintView(image: $image) { savedImage in
                    image = savedImage
                }
                .navigationTitle("Rysowanie")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Gotowe") { showPaint = false }
                    }
                }
            }
        }
        .alert("Blad", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMsg) }
    }

    private func loadNote() {
        let result = noteManager.loadNote(name: noteName)
        image = result.image
        text  = result.text
    }

    private func save() {
        do {
            let img = image ?? UIImage()
            try noteManager.saveNote(name: noteName, image: img, text: text)
            showSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSaved = false }
        } catch {
            errorMsg  = "Blad zapisu: \(error.localizedDescription)"
            showError = true
        }
    }
}
