import SwiftUI
import SafariServices

@available(iOS 26.0, *)
struct BookmarkDetailView2: View {
    let bookmarkId: String
    @Binding var useNativeWebView: Bool

    // MARK: - States

    @State private var viewModel: BookmarkDetailViewModel
    @State private var webViewHeight: CGFloat = 300
    @State private var showingFontSettings = false
    @State private var showingLabelsSheet = false
    @State private var readingProgress: Double = 0.0
    @State private var scrollViewHeight: CGFloat = 1
    @State private var currentScrollOffset: CGFloat = 0
    @State private var showJumpToProgressButton: Bool = false
    @State private var scrollPosition = ScrollPosition(edge: .top)
    @State private var showingImageViewer = false

    // MARK: - Envs

    @EnvironmentObject var playerUIState: PlayerUIState
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss

    private let headerHeight: CGFloat = 360

    init(bookmarkId: String, useNativeWebView: Binding<Bool>, viewModel: BookmarkDetailViewModel = BookmarkDetailViewModel()) {
        self.bookmarkId = bookmarkId
        self._useNativeWebView = useNativeWebView
        self.viewModel = viewModel
    }

    var body: some View {
        mainView
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            // Progress bar at top
            ProgressView(value: readingProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 3)

            // Main scroll content
            scrollViewContent
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingFontSettings) {
            fontSettingsSheet
        }
        .sheet(isPresented: $showingLabelsSheet) {
            BookmarkLabelsView(bookmarkId: bookmarkId, initialLabels: viewModel.bookmarkDetail.labels)
        }
        .sheet(isPresented: $showingImageViewer) {
            ImageViewerView(imageUrl: viewModel.bookmarkDetail.imageUrl)
        }
        .onChange(of: showingFontSettings) { _, isShowing in
            if !isShowing {
                Task {
                    await viewModel.loadBookmarkDetail(id: bookmarkId)
                }
            }
        }
        .onChange(of: showingLabelsSheet) { _, isShowing in
            if !isShowing {
                Task {
                    await viewModel.refreshBookmarkDetail(id: bookmarkId)
                }
            }
        }
        .onChange(of: viewModel.readProgress) { _, progress in
            showJumpToProgressButton = progress > 0 && progress < 100
        }
        .task {
            await viewModel.loadBookmarkDetail(id: bookmarkId)
            await viewModel.loadArticleContent(id: bookmarkId)
        }
    }

    private var scrollViewContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header image
                headerView

                // Content
                VStack(alignment: .leading, spacing: 16) {
                    // Spacer for header
                    Color.clear.frame(height: viewModel.bookmarkDetail.imageUrl.isEmpty ? 84 : headerHeight)

                    // Title section
                    titleSection

                    Divider().padding(.horizontal)

                    // Jump to last position button
                    if showJumpToProgressButton {
                        jumpButton
                    }

                    // Article content (WebView)
                    articleContent
                }
                .frame(maxWidth: .infinity)
            }
        }
        .clipped()
        .ignoresSafeArea(edges: .top)
        .scrollPosition($scrollPosition)
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { oldValue, newValue in
                // Just track current offset, don't calculate yet
                currentScrollOffset = newValue
            }
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.containerSize.height
            } action: { oldValue, newValue in
                scrollViewHeight = newValue
            }
            .onScrollPhaseChange { oldPhase, newPhase in
                // Only calculate progress when scrolling ends
                if oldPhase == .interacting && newPhase == .idle {
                    let offset = currentScrollOffset
                    let maxOffset = webViewHeight - scrollViewHeight
                    let rawProgress = offset / (maxOffset > 0 ? maxOffset : 1)
                    let progress = min(max(rawProgress, 0), 1)

                    // Only update if change is significant (> 5%)
                    let threshold: Double = 0.05
                    if abs(progress - readingProgress) > threshold {
                        readingProgress = progress
                        viewModel.debouncedUpdateReadProgress(id: bookmarkId, progress: progress, anchor: nil)
                    }
                }
            }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Toggle button (left)
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                useNativeWebView.toggle()
            }) {
                Image(systemName: "sparkles")
                    .foregroundColor(.accentColor)
            }
        }

        // Top toolbar (right)
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

        // Bottom toolbar - Archive section
        if viewModel.isLoadingArticle == false && viewModel.isLoading == false {
            ToolbarItemGroup(placement: .bottomBar) {

                Spacer()

                Button(action: {
                    Task {
                        await viewModel.toggleFavorite(id: bookmarkId)
                    }
                }) {
                    Label(
                        viewModel.bookmarkDetail.isMarked ? "Favorited" : "Favorite",
                        systemImage: viewModel.bookmarkDetail.isMarked ? "star.fill" : "star"
                    )
                }
                .disabled(viewModel.isLoading)

                Button(action: {
                    Task {
                        await viewModel.archiveBookmark(id: bookmarkId, isArchive: !viewModel.bookmarkDetail.isArchived)
                    }
                }) {
                    Label(
                        viewModel.bookmarkDetail.isArchived ? "Unarchive" : "Archive",
                        systemImage: viewModel.bookmarkDetail.isArchived ? "checkmark.circle" : "archivebox"
                    )
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    private var fontSettingsSheet: some View {
        NavigationView {
            VStack {
                FontSettingsView()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer()
            }
            .navigationTitle("Font Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingFontSettings = false
                    }
                }
            }
        }
    }

    // MARK: - ViewBuilder

    @ViewBuilder
    private var headerView: some View {
        if !viewModel.bookmarkDetail.imageUrl.isEmpty {
            ZStack(alignment: .bottomTrailing) {
                CachedAsyncImage(url: URL(string: viewModel.bookmarkDetail.imageUrl))
                    .aspectRatio(contentMode: .fill)
                    .frame(height: headerHeight)
                    .clipped()

                // Zoom icon
                Button(action: {
                    showingImageViewer = true
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
            .frame(height: headerHeight)
            .ignoresSafeArea(edges: .top)
            .onTapGesture {
                showingImageViewer = true
            }
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

    private var metaInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.bookmarkDetail.authors.isEmpty {
                metaRow(icon: "person", text: (viewModel.bookmarkDetail.authors.count > 1 ? "Authors: " : "Author: ") + viewModel.bookmarkDetail.authors.joined(separator: ", "))
            }
            metaRow(icon: "calendar", text: formatDate(viewModel.bookmarkDetail.created))
            metaRow(icon: "textformat", text: "\(viewModel.bookmarkDetail.wordCount ?? 0) words • \(viewModel.bookmarkDetail.readingTime ?? 0) min read")

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
                    URLUtil.open(url: viewModel.bookmarkDetail.url, urlOpener: appSettings.urlOpener)
                }) {
                    Text((URLUtil.extractDomain(from: viewModel.bookmarkDetail.url) ?? "Open original page") + " open")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if appSettings.enableTTS {
                metaRow(icon: "speaker.wave.2") {
                    Button(action: {
                        viewModel.addBookmarkToSpeechQueue()
                        playerUIState.showPlayer()
                    }) {
                        Text("Read article aloud")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
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

    @ViewBuilder
    private var articleContent: some View {
        if let settings = viewModel.settings, !viewModel.articleContent.isEmpty {
            if #available(iOS 26.0, *) {
                NativeWebView(
                    htmlContent: viewModel.articleContent,
                    settings: settings,
                    onHeightChange: { height in
                        if webViewHeight != height {
                            webViewHeight = height
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                .frame(height: webViewHeight)
                .cornerRadius(14)
                .padding(.horizontal, 4)
            }
        } else if viewModel.isLoadingArticle {
            ProgressView("Loading article...")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            Button(action: {
                URLUtil.open(url: viewModel.bookmarkDetail.url, urlOpener: appSettings.urlOpener)
            }) {
                HStack {
                    Image(systemName: "safari")
                    Text((URLUtil.extractDomain(from: "open " + viewModel.bookmarkDetail.url) ?? "Open original page"))
                }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.top, 0)
        }
    }

    private var jumpButton: some View {
        Button(action: {
            let maxOffset = webViewHeight - scrollViewHeight
            let offset = maxOffset * (Double(viewModel.readProgress) / 100.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                scrollPosition = ScrollPosition(y: offset)
                showJumpToProgressButton = false
            }
        }) {
            Text("Jump to last read position (\(viewModel.readProgress)%)")
                .font(.subheadline)
                .padding(8)
                .frame(maxWidth: .infinity)
        }
        .background(Color.accentColor.opacity(0.15))
        .cornerRadius(8)
        .padding([.top, .horizontal])
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
            displayFormatter.locale = .autoupdatingCurrent
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        NavigationView {
            BookmarkDetailView2(
                bookmarkId: "123",
                useNativeWebView: .constant(true),
                viewModel: .init(MockUseCaseFactory())
            )
        }
    }
}
