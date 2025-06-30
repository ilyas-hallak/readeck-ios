import SwiftUI
import SafariServices

struct BookmarkDetailView: View {
    let bookmarkId: String
    @State private var viewModel = BookmarkDetailViewModel()
    @State private var webViewHeight: CGFloat = 300
    @State private var showingFontSettings = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header mit Bild
                if !viewModel.bookmarkDetail.imageUrl.isEmpty {
                    AsyncImage(url: URL(string: viewModel.bookmarkDetail.imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                    }
                    .frame(height: 200)
                    .clipped()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Titel
                    Text(viewModel.bookmarkDetail.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Meta-Informationen
                    metaInfoSection
                    
                    Divider()
                   
                    // Artikel-Inhalt mit WebView
                    if let settings = viewModel.settings, !viewModel.articleContent.isEmpty {
                        WebView(htmlContent: viewModel.articleContent, settings: settings) { height in
                            webViewHeight = height
                        }
                        .frame(height: webViewHeight)
                    } else if viewModel.isLoadingArticle {
                        ProgressView("Lade Artikel...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingFontSettings = true
                }) {
                    Image(systemName: "textformat")
                }
            }
        }
        .sheet(isPresented: $showingFontSettings) {
            NavigationView {
                FontSettingsView()
                    .navigationTitle("Schrift-Einstellungen")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Fertig") {
                                showingFontSettings = false
                            }
                        }
                    }
            }
        }
        .task {
            await viewModel.loadBookmarkDetail(id: bookmarkId)
            await viewModel.loadArticleContent(id: bookmarkId)
        }
    }
    
    private var metaInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.bookmarkDetail.authors.isEmpty {
                HStack {
                    Image(systemName: "person")
                    Text(viewModel.bookmarkDetail.authors.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "calendar")
                Text("Erstellt: \(formatDate(viewModel.bookmarkDetail.created))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "textformat")
                Text("\(viewModel.bookmarkDetail.wordCount ?? 0) Wörter • \(viewModel.bookmarkDetail.readingTime ?? 0) min Lesezeit")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "safari")
                Button(action: {
                    SafariUtil.openInSafari(url: viewModel.bookmarkDetail.url)
                }) {
                    Text("Original Seite öffnen")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Erstelle einen Formatter für das ISO8601-Format mit Millisekunden
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Fallback für Format ohne Millisekunden
        let isoFormatterNoMillis = ISO8601DateFormatter()
        isoFormatterNoMillis.formatOptions = [.withInternetDateTime]
        
        // Versuche beide Formate
        var date: Date?
        if let parsedDate = isoFormatter.date(from: dateString) {
            date = parsedDate
        } else if let parsedDate = isoFormatterNoMillis.date(from: dateString) {
            date = parsedDate
        }
        
        if let date = date {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            displayFormatter.locale = Locale(identifier: "de_DE")
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

#Preview {
    NavigationView {
        BookmarkDetailView(bookmarkId: "sample-id")
    }
}
