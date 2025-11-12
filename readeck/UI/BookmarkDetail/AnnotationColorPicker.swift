import SwiftUI

struct AnnotationColorPicker: View {
    let selectedText: String
    let onColorSelected: (AnnotationColor) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Highlight Text")
                .font(.headline)

            Text(selectedText)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            Text("Select Color")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                ForEach(Constants.annotationColors, id: \.self) { color in
                    ColorButton(color: color, onTap: handleColorSelection)
                }
            }

            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(maxWidth: 400)
    }

    private func handleColorSelection(_ color: AnnotationColor) {
        onColorSelected(color)
        dismiss()
    }
}

struct ColorButton: View {
    let color: AnnotationColor
    let onTap: (AnnotationColor) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: { onTap(color) }) {
            Circle()
                .fill(color.swiftUIColor(isDark: colorScheme == .dark))
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
        }
    }
}
