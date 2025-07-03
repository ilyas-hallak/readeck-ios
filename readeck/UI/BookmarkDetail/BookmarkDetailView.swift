import SwiftUI
import SafariServices

struct BookmarkDetailView: View {
    let bookmarkId: String
    @State private var viewModel = BookmarkDetailViewModel()
    @State private var webViewHeight: CGFloat = 300
    @State private var showingFontSettings = false
    
    private let headerHeight: CGFloat = 260
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack(alignment: .top) {
                    headerView(geometry: geometry)
                    VStack(alignment: .leading, spacing: 16) {
                        Color.clear.frame(height: viewModel.bookmarkDetail.imageUrl.isEmpty ? 84 : headerHeight)
                        titleSection
                        Divider().padding(.horizontal)
                        contentSection
                        Spacer(minLength: 40)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
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
    
    // MARK: - ViewBuilder
    
    @ViewBuilder
    private func headerView(geometry: GeometryProxy) -> some View {
        if !viewModel.bookmarkDetail.imageUrl.isEmpty {
            GeometryReader { geo in
                let offset = geo.frame(in: .global).minY
                ZStack(alignment: .top) {
                    AsyncImage(url: URL(string: viewModel.bookmarkDetail.imageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: headerHeight + (offset > 0 ? offset : 0))
                            .clipped()
                            .offset(y: (offset > 0 ? -offset : 0))
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: geometry.size.width, height: headerHeight)
                    }
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: headerHeight)
            .ignoresSafeArea(edges: .top)
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.bookmarkDetail.title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.bottom, 2)
                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
            metaInfoSection
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var contentSection: some View {
        if let settings = viewModel.settings, !viewModel.articleContent.isEmpty {
            WebView(htmlContent: viewModel.articleContent, settings: settings) { height in
                webViewHeight = height
            }
            .frame(height: webViewHeight)
            .cornerRadius(14)
            .padding(.horizontal)
        } else if viewModel.isLoadingArticle {
            ProgressView("Lade Artikel...")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            Button(action: {
                SafariUtil.openInSafari(url: viewModel.bookmarkDetail.url)
            }) {
                HStack {
                    Image(systemName: "safari")
                    Text((URLUtil.extractDomain(from: viewModel.bookmarkDetail.url) ?? "Original Seite") + " öffnen")
                }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.top, 32)
        }
    }
    
    private var metaInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.bookmarkDetail.authors.isEmpty {
                metaRow(icon: "person", text: (viewModel.bookmarkDetail.authors.count > 1 ? "Autor:innen: " : "Autor: ") + viewModel.bookmarkDetail.authors.joined(separator: ", "))
            }
            metaRow(icon: "calendar", text: formatDate(viewModel.bookmarkDetail.created))
            metaRow(icon: "textformat", text: "\(viewModel.bookmarkDetail.wordCount ?? 0) Wörter • \(viewModel.bookmarkDetail.readingTime ?? 0) min Lesezeit")
            metaRow(icon: "safari") {
                Button(action: {
                    SafariUtil.openInSafari(url: viewModel.bookmarkDetail.url)
                }) {
                    Text((URLUtil.extractDomain(from: viewModel.bookmarkDetail.url) ?? "Original Seite") + " öffnen")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // ViewBuilder für Meta-Infos
    @ViewBuilder
    private func metaRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func metaRow(icon: String, @ViewBuilder content: () -> some View) -> some View {
        HStack {
            Image(systemName: icon)
            content()
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoFormatterNoMillis = ISO8601DateFormatter()
        isoFormatterNoMillis.formatOptions = [.withInternetDateTime]
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
