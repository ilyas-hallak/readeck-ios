import SwiftUI
import Foundation
import SafariServices

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct BookmarkCardView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let bookmark: Bookmark
    let currentState: BookmarkState
    let layout: CardLayoutStyle
    let pendingDelete: PendingDelete?
    let onArchive: (Bookmark) -> Void
    let onDelete: (Bookmark) -> Void
    let onToggleFavorite: (Bookmark) -> Void
    let onUndoDelete: ((String) -> Void)?
    
    init(
        bookmark: Bookmark,
        currentState: BookmarkState,
        layout: CardLayoutStyle = .magazine,
        pendingDelete: PendingDelete? = nil,
        onArchive: @escaping (Bookmark) -> Void,
        onDelete: @escaping (Bookmark) -> Void,
        onToggleFavorite: @escaping (Bookmark) -> Void,
        onUndoDelete: ((String) -> Void)? = nil
    ) {
        self.bookmark = bookmark
        self.currentState = currentState
        self.layout = layout
        self.pendingDelete = pendingDelete
        self.onArchive = onArchive
        self.onDelete = onDelete
        self.onToggleFavorite = onToggleFavorite
        self.onUndoDelete = onUndoDelete
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch layout {
                case .compact:
                    compactLayoutView
                case .magazine:
                    magazineLayoutView
                case .natural:
                    naturalLayoutView
                }
            }
            .opacity(pendingDelete != nil ? 0.4 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: pendingDelete != nil)
            
            // Undo toast overlay with progress background
            if let pendingDelete = pendingDelete {
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Undo button area with circular progress
                    HStack {
                        HStack(spacing: 8) {
                            // Circular progress indicator
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: 16, height: 16)
                                Circle()
                                    .trim(from: 0, to: CGFloat(pendingDelete.progress))
                                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 16, height: 16)
                                    .animation(.linear(duration: 0.1), value: pendingDelete.progress)
                            }
                            
                            Text("Deleting...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Undo") {
                            onUndoDelete?(bookmark.id)
                        }
                        .font(.caption.weight(.medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                        .onTapGesture {
                            onUndoDelete?(bookmark.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground).opacity(0.95))
                }
                .clipShape(RoundedRectangle(cornerRadius: layout == .compact ? 8 : 12))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if pendingDelete == nil {
                Button("Delete", role: .destructive) {
                    onDelete(bookmark)
                }
                .tint(.red)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if pendingDelete == nil {
                Button {
                    onArchive(bookmark)
                } label: {
                    if currentState == .archived {
                        Label("Restore", systemImage: "tray.and.arrow.up")
                    } else {
                        Label("Archive", systemImage: "archivebox")
                    }
                }
                .tint(currentState == .archived ? .blue : .orange)
                
                Button {
                    onToggleFavorite(bookmark)
                } label: {
                    Label(bookmark.isMarked ? "Remove" : "Favorite",
                          systemImage: bookmark.isMarked ? "heart.slash" : "heart.fill")
                }
                .tint(bookmark.isMarked ? .gray : .pink)
            }
        }
    }
    
    private var compactLayoutView: some View {
        HStack(alignment: .top, spacing: 12) {
            CachedAsyncImage(url: imageURL)
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bookmark.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if !bookmark.description.isEmpty {
                    Text(bookmark.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                HStack(spacing: 4) {
                    if !bookmark.siteName.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "globe")
                            Text(bookmark.siteName)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let readingTime = bookmark.readingTime, readingTime > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                            Text("\(readingTime) min")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(R.color.bookmark_list_bg))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var magazineLayoutView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                CachedAsyncImage(url: imageURL)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                if bookmark.readProgress > 0 && bookmark.isArchived == false && bookmark.isMarked == false {
                    ZStack {
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 36, height: 36)
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                            .frame(width: 32, height: 32)
                        Circle()
                            .trim(from: 0, to: CGFloat(bookmark.readProgress) / 100)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 32, height: 32)
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("\(bookmark.readProgress)")
                                .font(.caption2)
                                .bold()
                            Text("%")
                                .font(.system(size: 8))
                                .baselineOffset(2)
                        }
                    }
                    .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bookmark.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if let publishedDate = formattedPublishedDate {
                            HStack {
                                Label(publishedDate, systemImage: "calendar")
                                Spacer()
                            }
                            Spacer()
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
                        Label((URLUtil.extractDomain(from: bookmark.url) ?? "Original Site") + " open", systemImage: "safari")
                            .onTapGesture {
                                SafariUtil.openInSafari(url: bookmark.url)
                            }
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(R.color.bookmark_list_bg))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var naturalLayoutView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                CachedAsyncImage(url: imageURL)
                    .aspectRatio(contentMode: .fit)
                    .frame(minHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                if bookmark.readProgress > 0 && bookmark.isArchived == false && bookmark.isMarked == false {
                    ZStack {
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 36, height: 36)
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                            .frame(width: 32, height: 32)
                        Circle()
                            .trim(from: 0, to: CGFloat(bookmark.readProgress) / 100)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 32, height: 32)
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("\(bookmark.readProgress)")
                                .font(.caption2)
                                .bold()
                            Text("%")
                                .font(.system(size: 8))
                                .baselineOffset(2)
                        }
                    }
                    .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bookmark.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if let publishedDate = formattedPublishedDate {
                            HStack {
                                Label(publishedDate, systemImage: "calendar")
                                Spacer()
                            }
                            Spacer()
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
                        Label((URLUtil.extractDomain(from: bookmark.url) ?? "Original Site") + " open", systemImage: "safari")
                            .onTapGesture {
                                SafariUtil.openInSafari(url: bookmark.url)
                            }
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(R.color.bookmark_list_bg))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
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
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        guard let date = formatter.date(from: published) else {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            guard let fallbackDate = formatter.date(from: published) else {
                return nil
            }
            return formatDate(fallbackDate)
        }
        
        return formatDate(date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // Today
        if calendar.isDate(date, inSameDayAs: now) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: date))"
        }
        
        // Yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Yesterday, \(formatter.string(from: date))"
        }
        
        // This week
        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, HH:mm"
            return formatter.string(from: date)
        }
        
        // This year
        if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            let formatter = DateFormatter()
            formatter.dateFormat = "d. MMM, HH:mm"
            return formatter.string(from: date)
        }
        
        // Other years
        let formatter = DateFormatter()
        formatter.dateFormat = "d. MMM yyyy"
        return formatter.string(from: date)
    }
    
    private var imageURL: URL? {
        if let imageUrl = bookmark.resources.image?.src {
            return URL(string: imageUrl)
        }
        return nil
    }
}

struct IconBadge: View {
    let systemName: String
    let color: Color
    
    var body: some View {
        Image(systemName: systemName)
            .frame(width: 20, height: 20)
            .background(color)
            .foregroundColor(.white)
            .clipShape(Circle())
    }
}