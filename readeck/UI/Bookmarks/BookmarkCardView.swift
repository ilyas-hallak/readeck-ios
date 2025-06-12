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
                // Status-Icons und Action-Button
                HStack {
                    HStack(spacing: 6) {
                        if bookmark.isMarked {
                            IconBadge(systemName: "heart.fill", color: .red)
                        }
                        if bookmark.isArchived {
                            IconBadge(systemName: "archivebox.fill", color: .gray)
                        }
                        if bookmark.hasArticle {
                            IconBadge(systemName: "doc.text.fill", color: .green)
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
                
                // Meta-Info mit Datum
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if !bookmark.siteName.isEmpty {
                            Label(bookmark.siteName, systemImage: "globe")
                        }
                        
                        Spacer()
                        
                        if let readingTime = bookmark.readingTime, readingTime > 0 {
                            Label("\(readingTime) min", systemImage: "clock")
                        }
                    }
                    
                    // Veröffentlichungsdatum
                    if let publishedDate = formattedPublishedDate {
                        HStack {
                            Label(publishedDate, systemImage: "calendar")
                            Spacer()
                        }
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
    
    // MARK: - Computed Properties
    
    private var formattedPublishedDate: String? {
        guard let published = bookmark.published, 
              !published.isEmpty else { 
            return nil 
        }
        
        // Prüfe auf Unix Epoch (1970-01-01) - bedeutet "kein Datum"
        if published.contains("1970-01-01") {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let date = formatter.date(from: published) else {
            // Fallback ohne Millisekunden
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            guard let fallbackDate = formatter.date(from: published) else {
                return nil
            }
            return formatDate(fallbackDate)
        }
        
        return formatDate(date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        // Heute
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Heute, \(formatter.string(from: date))"
        }
        
        // Gestern
        if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Gestern, \(formatter.string(from: date))"
        }
        
        // Diese Woche
        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, HH:mm"
            return formatter.string(from: date)
        }
        
        // Dieses Jahr
        if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            let formatter = DateFormatter()
            formatter.dateFormat = "d. MMM, HH:mm"
            return formatter.string(from: date)
        }
        
        // Andere Jahre
        let formatter = DateFormatter()
        formatter.dateFormat = "d. MMM yyyy"
        return formatter.string(from: date)
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

struct IconBadge: View {
    let systemName: String
    let color: Color
    
    var body: some View {
        Image(systemName: systemName)
            .font(.caption2)
            .padding(6)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Circle())
    }
}

