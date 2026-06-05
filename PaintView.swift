import SwiftUI
import PencilKit

struct PaintView: View {
    @Binding var image: UIImage?

    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var showSaved  = false

    var onSave: (UIImage) -> Void

    var body: some View {
        VStack(spacing: 0) {
            CanvasRepresentable(canvasView: $canvasView, toolPicker: $toolPicker)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .cornerRadius(12)
                .padding(8)

            HStack(spacing: 12) {
                Button(action: clearCanvas) {
                    Label("Wyczysc", systemImage: "trash")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Spacer()

                if showSaved {
                    Label("Zapisano!", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }

                Button(action: saveDrawing) {
                    Label("Zapisz", systemImage: "square.and.arrow.down")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .onAppear {
            // Zaladuj istniejacy rysunek
            if let img = image {
                if let drawing = try? PKDrawing(data: img.pngData() ?? Data()) {
                    canvasView.drawing = drawing
                }
            }
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        }
    }

    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
    }

    private func saveDrawing() {
        let img = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
        onSave(img)
        showSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSaved = false }
    }
}

struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .white
        canvasView.drawingPolicy   = .anyInput
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
