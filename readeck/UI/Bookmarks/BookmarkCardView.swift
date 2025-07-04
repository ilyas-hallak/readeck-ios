import SwiftUI
import SafariServices

struct BookmarkCardView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let bookmark: Bookmark
    let currentState: BookmarkState
    let onArchive: (Bookmark) -> Void
    let onDelete: (Bookmark) -> Void
    let onToggleFavorite: (Bookmark) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
            } placeholder: {
                
                Image(R.image.placeholder.name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bookmark.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        
                        // Veröffentlichungsdatum
                        if let publishedDate = formattedPublishedDate {
                            HStack {
                                Label(publishedDate, systemImage: "calendar")
                                Spacer()
                            }
                            
                            Spacer() // show spacer only if we have the published Date
                        }
                        
                        if let readingTime = bookmark.readingTime, readingTime > 0 {
                            Label("\(readingTime) min", systemImage: "clock")
                        }
                    }
                    
                    HStack {
                        if !bookmark.siteName.isEmpty {
                            Label(bookmark.siteName, systemImage: "globe")
                        }
                    }
                    HStack {
                        
                        Label((URLUtil.extractDomain(from: bookmark.url) ?? "Original Seite") + " öffnen", systemImage: "safari")
                            .onTapGesture {
                                SafariUtil.openInSafari(url: bookmark.url)
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
        .background(Color(R.color.bookmark_list_bg))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: colorScheme == .light ? .black.opacity(0.1) : .white.opacity(0.1), radius: 2, x: 0, y: 1)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Löschen", role: .destructive) {
                onDelete(bookmark)
            }
            .tint(.red)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            // Archivieren (links)
            Button {
                onArchive(bookmark)
            } label: {
                if currentState == .archived {
                    Label("Wiederherstellen", systemImage: "tray.and.arrow.up")
                } else {
                    Label("Archivieren", systemImage: "archivebox")
                }
            }
            .tint(currentState == .archived ? .blue : .orange)
            
            Button {
                onToggleFavorite(bookmark)
            } label: {
                Label(bookmark.isMarked ? "Entfernen" : "Favorit",
                      systemImage: bookmark.isMarked ? "heart.slash" : "heart.fill")
            }
            .tint(bookmark.isMarked ? .gray : .pink)
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedPublishedDate: String? {
        guard let published = bookmark.published, !published.isEmpty else {
            return nil 
        }
        
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

