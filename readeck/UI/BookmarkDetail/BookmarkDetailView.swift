import SwiftUI
import SafariServices

struct BookmarkDetailView: View {
    let bookmarkId: String
    @State private var viewModel = BookmarkDetailViewModel()
    @State private var webViewHeight: CGFloat = 300
    @State private var showingFontSettings = false
    @State private var showingLabelsSheet = false
    @EnvironmentObject var playerUIState: PlayerUIState
    
    private let headerHeight: CGFloat = 320
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack(alignment: .top) {
                    headerView(geometry: geometry)
                    VStack(alignment: .center, spacing: 16) {
                        Color.clear.frame(height: viewModel.bookmarkDetail.imageUrl.isEmpty ? 84 : headerHeight)
                        titleSection
                        Divider().padding(.horizontal)
                        contentSection
                        Spacer(minLength: 40)
                        if viewModel.isLoadingArticle == false {
                            archiveSection
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                                .animation(.easeInOut, value: viewModel.articleContent)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: {
                        showingLabelsSheet = true
                    }) {
                        Image(systemName: "tag")
                    }
                    
                    Button(action: {
                        showingFontSettings = true
                    }) {
                        Image(systemName: "textformat")
                    }
                }
            }
        }
        .sheet(isPresented: $showingFontSettings) {
            NavigationView {                
                VStack {
                    FontSettingsView()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    Spacer()
                }
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
        .sheet(isPresented: $showingLabelsSheet) {
            BookmarkLabelsView(bookmarkId: bookmarkId, initialLabels: viewModel.bookmarkDetail.labels)
        }
        .onChange(of: showingFontSettings) { _, isShowing in
            if !isShowing {
                // Reload settings when sheet is dismissed
                Task {
                    await viewModel.loadBookmarkDetail(id: bookmarkId)
                }
            }
        }
        .onChange(of: showingLabelsSheet) { _, isShowing in
            if !isShowing {
                // Reload bookmark detail when labels sheet is dismissed
                Task {
                    await viewModel.refreshBookmarkDetail(id: bookmarkId)
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
                    // Gradient overlay für bessere Button-Sichtbarkeit
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(1.0),
                            Color.black.opacity(0.9),
                            Color.black.opacity(0.7),
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.2),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 240)
                    .frame(maxWidth: .infinity)
                    .offset(y: (offset > 0 ? -offset : 0))
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
                withAnimation(.easeInOut(duration: 0.3)) {
                    webViewHeight = height
                }
            }
            .frame(height: webViewHeight)
            .cornerRadius(14)
            .padding(.horizontal)
            .animation(.easeInOut, value: webViewHeight)
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
            .padding(.top, 4)
        }
    }
    
    private var metaInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.bookmarkDetail.authors.isEmpty {
                metaRow(icon: "person", text: (viewModel.bookmarkDetail.authors.count > 1 ? "Autor:innen: " : "Autor: ") + viewModel.bookmarkDetail.authors.joined(separator: ", "))
            }
            metaRow(icon: "calendar", text: formatDate(viewModel.bookmarkDetail.created))
            metaRow(icon: "textformat", text: "\(viewModel.bookmarkDetail.wordCount ?? 0) Wörter • \(viewModel.bookmarkDetail.readingTime ?? 0) min Lesezeit")
            
            // Labels section
            if !viewModel.bookmarkDetail.labels.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "tag")
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(viewModel.bookmarkDetail.labels, id: \.self) { label in
                                Text(label)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.accentColor.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        .padding(.trailing, 8)
                    }
                }
            }
            
            metaRow(icon: "safari") {
                Button(action: {
                    SafariUtil.openInSafari(url: viewModel.bookmarkDetail.url)
                }) {
                    Text((URLUtil.extractDomain(from: viewModel.bookmarkDetail.url) ?? "Original Seite") + " öffnen")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            metaRow(icon: "speaker.wave.2") {
                Button(action: {
                    viewModel.addBookmarkToSpeechQueue()
                    playerUIState.showPlayer()
                }) {
                    Text("Artikel vorlesen")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
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
    
    private var archiveSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Fertig mit Lesen?")
                .font(.headline)
                .padding(.top, 24)
            VStack(alignment: .center, spacing: 16) {
                Button(action: {
                    Task {
                        await viewModel.toggleFavorite(id: bookmarkId)
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.bookmarkDetail.isMarked ? "star.fill" : "star")
                            .foregroundColor(viewModel.bookmarkDetail.isMarked ? .yellow : .gray)
                        Text(viewModel.bookmarkDetail.isMarked ? "Favorit" : "Als Favorit markieren")
                    }
                    .font(.title3.bold())
                    .frame(maxHeight: 60)
                    .padding(10)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)
                
                // Archivieren-Button
                Button(action: {
                    Task {
                        await viewModel.archiveBookmark(id: bookmarkId)
                    }
                }) {
                    HStack {
                        Image(systemName: "archivebox")
                        Text("Bookmark archivieren")
                    }
                    .font(.title3.bold())
                    .frame(maxHeight: 60)
                    .padding(10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
}

#Preview {
    NavigationView {
        BookmarkDetailView(bookmarkId: "sample-id")
    }
}
