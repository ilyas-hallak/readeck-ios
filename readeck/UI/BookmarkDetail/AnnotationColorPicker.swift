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
                ColorButton(color: .yellow, onTap: handleColorSelection)
                ColorButton(color: .green, onTap: handleColorSelection)
                ColorButton(color: .blue, onTap: handleColorSelection)
                ColorButton(color: .red, onTap: handleColorSelection)
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

enum AnnotationColor: String, CaseIterable {
    case yellow = "yellow"
    case green = "green"
    case blue = "blue"
    case red = "red"

    func swiftUIColor(isDark: Bool) -> Color {
        switch self {
        case .yellow:
            return isDark ? Color(red: 158/255, green: 117/255, blue: 4/255) : Color(red: 107/255, green: 79/255, blue: 3/255)
        case .green:
            return isDark ? Color(red: 132/255, green: 204/255, blue: 22/255) : Color(red: 57/255, green: 88/255, blue: 9/255)
        case .blue:
            return isDark ? Color(red: 9/255, green: 132/255, blue: 159/255) : Color(red: 7/255, green: 95/255, blue: 116/255)
        case .red:
            return isDark ? Color(red: 152/255, green: 43/255, blue: 43/255) : Color(red: 103/255, green: 29/255, blue: 29/255)
        }
    }
}
