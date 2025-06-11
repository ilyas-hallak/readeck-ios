import SwiftUI

struct BookmarkCardView: View {
    let bookmark: Bookmark
    let currentState: BookmarkState
    let onArchive: (Bookmark) -> Void
    let onDelete: (Bookmark) -> Void
    let onToggleFavorite: (Bookmark) -> Void
    
    @State private var showingActionSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Vorschaubild - verwende image oder thumbnail
            AsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                // Status-Badges und Action-Button
                HStack {
                    HStack(spacing: 4) {
                        if bookmark.isMarked {
                            Badge(text: "Markiert", color: .blue)
                        }
                        if bookmark.isArchived {
                            Badge(text: "Archiviert", color: .gray)
                        }
                        if bookmark.hasArticle {
                            Badge(text: "Artikel", color: .green)
                        }
                    }
                    
                    Spacer()
                    
                    // Action Menu Button
                    Button(action: {
                        showingActionSheet = true
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Titel
                Text(bookmark.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Beschreibung
                if !bookmark.description.isEmpty {
                    Text(bookmark.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                // Meta-Info
                HStack {
                    if !bookmark.siteName.isEmpty {
                        Label(bookmark.siteName, systemImage: "globe")
                    }
                    
                    Spacer()
                    
                    if let readingTime = bookmark.readingTime, readingTime > 0 {
                        Label("\(readingTime) min", systemImage: "clock")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                // Progress Bar für Lesefortschritt
                if bookmark.readProgress > 0 {
                    ProgressView(value: Double(bookmark.readProgress), total: 100)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .confirmationDialog("Bookmark Aktionen", isPresented: $showingActionSheet) {
            actionButtons
        }
    }
    
    private var actionButtons: some View {
        Group {
            // Favorit Toggle
            Button(bookmark.isMarked ? "Favorit entfernen" : "Als Favorit markieren") {
                onToggleFavorite(bookmark)
            }
            
            // Archivieren/Dearchivieren basierend auf aktuellem State
            if currentState == .archived {
                Button("Aus Archiv entfernen") {
                    onArchive(bookmark)
                }
            } else {
                Button("Archivieren") {
                    onArchive(bookmark)
                }
            }
            
            // Permanent löschen (immer verfügbar)
            Button("Permanent löschen", role: .destructive) {
                onDelete(bookmark)
            }
            
            Button("Abbrechen", role: .cancel) { }
        }
    }
    
    private var imageURL: URL? {
        // Bevorzuge image, dann thumbnail, dann icon
        if let imageUrl = bookmark.resources.image?.src {
            return URL(string: imageUrl)
        } else if let thumbnailUrl = bookmark.resources.thumbnail?.src {
            return URL(string: thumbnailUrl)
        } else if let iconUrl = bookmark.resources.icon?.src {
            return URL(string: iconUrl)
        }
        return nil
    }
}

struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

