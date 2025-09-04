import SwiftUI

struct UndoToastView: View {
    let bookmarkTitle: String
    let progress: Double
    let onUndo: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Bookmark deleted")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(bookmarkTitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            Spacer()
            
            Button("Undo") {
                onUndo()
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.2))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            // Progress bar at bottom
            VStack {
                Spacer()
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white.opacity(0.8)))
                    .scaleEffect(y: 0.5)
            }
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    VStack {
        Spacer()
        UndoToastView(
            bookmarkTitle: "How to Build Great Products",
            progress: 0.6,
            onUndo: {}
        )
        .padding()
    }
    .background(Color.gray.opacity(0.3))
}