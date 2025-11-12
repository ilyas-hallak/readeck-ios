import SwiftUI

struct AnnotationColorOverlay: View {
    let onColorSelected: (AnnotationColor) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Constants.annotationColors, id: \.self) { color in
                ColorButton(color: color, onTap: onColorSelected)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
        )
    }

    private struct ColorButton: View {
        let color: AnnotationColor
        let onTap: (AnnotationColor) -> Void
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            Button(action: { onTap(color) }) {
                Circle()
                    .fill(color.swiftUIColor(isDark: colorScheme == .dark))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    AnnotationColorOverlay { color in
        print("Selected: \(color)")
    }
    .padding()
}
