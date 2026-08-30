import SwiftUI
import SafariServices

// PreferenceKey for content height tracking
struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: Double = 0
    static func reduce(value: inout Double, nextValue: () -> Double) {
        value = nextValue()
    }
}

struct ArticleReaderLegacyView: View {
    let bookmarkId: String
    @Binding var useNativeWebView: Bool

    // MARK: - States

    @State private var viewModel: BookmarkDetailViewModel
    @State private var webViewHeight: Double = 300
    @State private var initialContentEndPosition: Double = 0
    @State private var showingFontSettings = false
    @State private var showingLabelsSheet = false
    @State private var showingAnnotationsSheet = false
    @State private var readingProgress = 0.0
    @State private var lastSentProgress = 0.0
    @State private var showJumpToProgressButton = false
    @State private var scrollPosition = ScrollPosition(edge: .top)
    @State private var showingImageViewer = false
    @State private var showingDeleteConfirmation = false

    // MARK: - Envs

    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let headerHeight: Double = 360

    init(bookmarkId: String, useNativeWebView: Binding<Bool>, viewModel: BookmarkDetailViewModel = BookmarkDetailViewModel()) {
        self.bookmarkId = bookmarkId
        self._useNativeWebView = useNativeWebView
        self.viewModel = viewModel
    }

    var body: some View {
        mainContent
            .frame(maxWidth: .infinity)
            .background(readerTheme.backgroundColor.ignoresSafeArea())
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            if viewModel.showProgressBar {
                ProgressView(value: readingProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 3)
            }
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        ZStack(alignment: .top) {
                            if viewModel.showHeroImage {
                                headerView(width: geometry.size.width)
                            }
                            VStack(alignment: .leading, spacing: 16) {
                            Color.clear.frame(width: geometry.size.width, height: viewModel.hasVisibleHeroImage ? headerHeight : 84)
                            titleSection
                            Divider().padding(.horizontal)
                            if showJumpToProgressButton {
                                JumpButton(containerHeight: geometry.size.height)
                            }
                            if let settings = viewModel.settings, !viewModel.articleContent.isEmpty {
                                WebView(
                                    htmlContent: viewModel.articleContent,
                                    settings: settings,
                                    onHeightChange: { height in
                                        if webViewHeight != height {
                                            webViewHeight = height
                                        }
                                    },
                                    selectedAnnotationId: viewModel.selectedAnnotationId,
                                    onAnnotationCreated: { color, text, startOffset, endOffset, startSelector, endSelector in
                                        Task {
                                            await viewModel.createAnnotation(
                                                bookmarkId: bookmarkId,
                                                color: color,
                                                text: text,
                                                startOffset: startOffset,
                                                endOffset: endOffset,
                                                startSelector: startSelector,
                                                endSelector: endSelector
                                            )
                                        }
                                    },
                                    onScrollToPosition: { position in
                                        // Calculate scroll position: add header height and webview offset
                                        let imageHeight: CGFloat = viewModel.hasVisibleHeroImage ? headerHeight : 84
                                        let targetPosition = imageHeight + position

                                        // Scroll to the annotation
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            scrollPosition = ScrollPosition(y: targetPosition)
                                        }
                                    }
                                )
                                .frame(height: webViewHeight)
                                .cornerRadius(14)
                                .padding(.horizontal, 4)
                                .id(settings.webViewIdentifier)
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
                                        Text(URLUtil.openUrlLabel(for: viewModel.bookmarkDetail.url))
                                    }
                                    .font(.title3.bold())
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.horizontal)
                                .padding(.top, 0)
                            }

                            if viewModel.isLoadingArticle == false && viewModel.isLoading == false {
                                VStack(alignment: .center) {
                                    archiveSection
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                        .animation(.easeInOut, value: viewModel.articleContent)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                        // Invisible marker to measure total content height - placed AFTER all content
                        Color.clear
                            .frame(height: 1)
                            .background(
                                GeometryReader { endGeo in
                                    Color.clear.preference(
                                        key: ContentHeightPreferenceKey.self,
                                        value: endGeo.frame(in: .named("scrollView")).maxY
                                    )
                                }
                            )
                    }
                }
                .coordinateSpace(name: "scrollView")
                .clipped()
                .ignoresSafeArea(edges: .top)
                .scrollPosition($scrollPosition)
                .onPreferenceChange(ContentHeightPreferenceKey.self) { endPosition in
                    let containerHeight = geometry.size.height

                    // Update initial position if content grows (WebView still loading) or first time
                    // We always take the maximum position seen (when scrolled to top, this is total content height)
                    if endPosition > initialContentEndPosition && endPosition > containerHeight * 1.2 {
                        initialContentEndPosition = endPosition
                        Logger.ui.debug("Content end position updated: \(Int(endPosition)) (container: \(Int(containerHeight)))")
                    }

                    // Calculate progress from how much the end marker has moved up
                    guard initialContentEndPosition > 0 else {
                        Logger.ui.debug("Waiting for content to load... current: \(Int(endPosition)), container: \(Int(containerHeight))")
                        return
                    }

                    let totalScrollableDistance = initialContentEndPosition - containerHeight

                    guard totalScrollableDistance > 0 else {
                        Logger.ui.debug("Content not scrollable: initial=\(initialContentEndPosition), container=\(containerHeight)")
                        return
                    }

                    // How far has the marker moved from its initial position?
                    let scrolled = initialContentEndPosition - endPosition
                    let rawProgress = scrolled / totalScrollableDistance
                    var progress = min(max(rawProgress, 0), 1)

                    // Lock progress at 100% once reached (don't go back to 99% due to pixel variations)
                    if lastSentProgress >= 0.995 {
                        progress = max(progress, 1.0)
                    }

                    Logger.ui.debug("Progress: \(Int(progress * 100))% | scrolled: \(Int(scrolled)) / \(Int(totalScrollableDistance)) | endPos: \(Int(endPosition))")

                    // Check if we should update: threshold OR reaching 100% for first time
                    let threshold: Double = 0.03
                    let reachedEnd = progress >= 1.0 && lastSentProgress < 1.0
                    let shouldUpdate = abs(progress - lastSentProgress) >= threshold || reachedEnd

                    if shouldUpdate {
                        Logger.ui.debug("Updating progress: \(Int(lastSentProgress * 100))% → \(Int(progress * 100))%\(reachedEnd ? " [END]" : "")")
                        lastSentProgress = progress
                        readingProgress = progress
                        viewModel.debouncedUpdateReadProgress(id: bookmarkId, progress: progress, anchor: nil)
                    }
                }
            }
        }
        // Everything inside the reader adopts the theme's brightness so system-tinted
        // elements stay legible on a light theme while the app runs in dark mode, and
        // vice versa. Applied here so the presented sheets keep the app appearance.
        .environment(\.colorScheme, readerTheme.colorScheme)
        .navigationBarTitleDisplayMode(.inline)
        // Local to this screen on purpose: OLEDTheme.swift owns the global
        // UINavigationBar appearance proxy, and a second writer would leave the
        // bookmark list tinted after leaving the reader.
        .toolbarBackground(readerTheme.backgroundColor, for: .navigationBar)
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        .toolbarColorScheme(readerTheme.colorScheme, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingLabelsSheet = true
                    } label: {
                        Label("Manage Labels".localized, systemImage: "tag")
                    }

                    Button {
                        showingAnnotationsSheet = true
                    } label: {
                        Label("Annotations".localized, systemImage: "pencil.line")
                    }

                    ShareLink(item: viewModel.shareContent) {
                        Label("Share".localized, systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showingFontSettings = true
                    } label: {
                        Label("Font Settings".localized, systemImage: "textformat")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete".localized, systemImage: "trash")
                    }
                    .disabled(!appSettings.isNetworkConnected)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingFontSettings) {
            NavigationView {
                FontSelectionView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingFontSettings = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingLabelsSheet) {
            BookmarkLabelsView(bookmarkId: bookmarkId, initialLabels: viewModel.bookmarkDetail.labels)
        }
        .sheet(isPresented: $showingAnnotationsSheet) {
            AnnotationsListView(bookmarkId: bookmarkId) { annotationId in
                viewModel.selectedAnnotationId = annotationId
            }
        }
        .sheet(isPresented: $showingImageViewer) {
            ImageViewerView(imageUrl: viewModel.bookmarkDetail.imageUrl)
        }
        .alert(
            "Delete this bookmark?".localized,
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Cancel".localized, role: .cancel) {}
            Button("Delete".localized, role: .destructive) {
                Task {
                    let success = await viewModel.deleteBookmark(id: bookmarkId)
                    if success {
                        // In "next article" mode the bookmarks list drives navigation
                        // to the following item; dismissing here would pop to the list.
                        if appSettings.archiveAdvanceMode != .nextArticle {
                            dismiss()
                        }
                    }
                }
            }
        } message: {
            Text("This action cannot be undone.".localized)
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
        .onChange(of: showingAnnotationsSheet) { _, isShowing in
            if !isShowing {
                // Reload bookmark detail when labels sheet is dismissed
                Task {
                    await viewModel.refreshBookmarkDetail(id: bookmarkId)
                }
            }
        }
        .onChange(of: viewModel.readProgress) { _, progress in
            showJumpToProgressButton = progress > 0 && progress < 100
        }
        .onChange(of: viewModel.selectedAnnotationId) { _, _ in
            // Trigger WebView reload when annotation is selected
        }
        .task {
            await viewModel.loadBookmarkDetail(id: bookmarkId)
            await viewModel.waitForArticleReady(id: bookmarkId)
            await viewModel.loadArticleContent(id: bookmarkId)
        }
    }

    // MARK: - ViewBuilder

    @ViewBuilder
    private func headerView(width: Double) -> some View {
        if !viewModel.bookmarkDetail.imageUrl.isEmpty {
            ZStack(alignment: .bottomTrailing) {
                CachedAsyncImage(url: URL(string: viewModel.bookmarkDetail.imageUrl))
                    .scaledToFill()
                    .frame(width: width, height: headerHeight)
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
            .accessibilityAddTraits(.isButton)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(viewModel.bookmarkDetail.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(nativeTextColor)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                Spacer()
                Button(action: {
                    URLUtil.open(url: viewModel.bookmarkDetail.url, urlOpener: appSettings.urlOpener)
                }) {
                    Image(systemName: "safari")
                        .font(.title3)
                        .foregroundColor(nativeSecondaryTextColor)
                }
            }
            metaInfoSection
            if viewModel.canSummarize {
                ArticleSummaryCardView(viewModel: viewModel.summaryViewModel, backgroundColor: summaryCardBackgroundColor, textColor: nativeTextColor)
            }
        }
        .padding(.horizontal)
    }

    // The page background now carries the theme, so the card needs its own tint to
    // stay visible instead of a translucent copy of the same color.
    private var summaryCardBackgroundColor: Color {
        readerTheme.surfaceColor
    }

    @ViewBuilder
    private var contentSection: some View {
        if let settings = viewModel.settings, !viewModel.articleContent.isEmpty {
            WebView(htmlContent: viewModel.articleContent, settings: settings) { height in
                withAnimation(.easeInOut(duration: 0.1)) {
                    webViewHeight = height
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: webViewHeight)
            .cornerRadius(14)
            .padding(.horizontal, 4)
            .animation(.easeInOut, value: webViewHeight)
            .id(settings.webViewIdentifier)
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
                    Text(URLUtil.openUrlLabel(for: viewModel.bookmarkDetail.url))
                }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.top, 0)
        }
    }

    private var metaInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.bookmarkDetail.authors.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person")
                        .foregroundColor(nativeSecondaryTextColor)
                    Text(viewModel.bookmarkDetail.authors.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(nativeSecondaryTextColor)
                    Text("·")
                        .font(.subheadline)
                        .foregroundColor(nativeSecondaryTextColor)
                    Text(formatDate(viewModel.bookmarkDetail.created))
                        .font(.subheadline)
                        .foregroundColor(nativeSecondaryTextColor)
                }
            } else {
                metaRow(icon: "calendar", text: formatDate(viewModel.bookmarkDetail.created))
            }
            if viewModel.showWordCount {
                metaRow(icon: "textformat", text: "\(viewModel.bookmarkDetail.wordCount ?? 0) words • \(viewModel.bookmarkDetail.readingTime ?? 0) min read")
            }

            // Labels section
            if !viewModel.bookmarkDetail.labels.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "tag")
                        .foregroundColor(nativeSecondaryTextColor)
                        .padding(.top, 2)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(viewModel.bookmarkDetail.labels, id: \.self) { label in
                                Text(label)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(nativeTextColor)
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


            if appSettings.enableTTS {
                metaRow(icon: "speaker.wave.2") {
                    Button(action: {
                        viewModel.addBookmarkToSpeechQueue()
                    }) {
                        Text("Read article aloud")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                metaRow(icon: "text.line.first.and.arrowtriangle.forward") {
                    Button(action: {
                        viewModel.addBookmarkToSpeechQueueNext()
                    }) {
                        Text("Listen Next")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Color Theme Helpers

    /// Single source of truth for the reader's colors, shared with the web view.
    private var readerTheme: ReaderTheme {
        ReaderTheme.resolve(settings: viewModel.settings, isDarkMode: colorScheme == .dark)
    }

    private var nativeTextColor: Color {
        readerTheme.textColor
    }

    private var nativeSecondaryTextColor: Color {
        readerTheme.secondaryTextColor
    }

    @ViewBuilder
    private func metaRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(nativeSecondaryTextColor)
            Text(text)
                .font(.subheadline)
                .foregroundColor(nativeSecondaryTextColor)
        }
    }

    @ViewBuilder
    private func metaRow(icon: String, @ViewBuilder content: () -> some View) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(nativeSecondaryTextColor)
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
        if let date {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            displayFormatter.locale = .autoupdatingCurrent
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    private var archiveSection: some View {
        VStack(spacing: 12) {
            Text("Finished reading?")
                .font(.headline)
                .padding(.top, 24)
            VStack(spacing: 16) {
                Button(action: {
                    Task {
                        await viewModel.toggleFavorite(id: bookmarkId)
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.bookmarkDetail.isMarked ? "heart.fill" : "heart")
                            .foregroundColor(viewModel.bookmarkDetail.isMarked ? .pink : .gray)
                        Text(viewModel.bookmarkDetail.isMarked ? "Favorite" : "Mark as favorite")
                    }
                    .font(.title3.bold())
                    .frame(maxHeight: 60)
                    .padding(10)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoading)

                // Archive button
                Button(action: {
                    Task {
                        await viewModel.archiveBookmark(id: bookmarkId, isArchive: !viewModel.bookmarkDetail.isArchived)
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.bookmarkDetail.isArchived ? "checkmark.circle" : "archivebox")
                        Text(viewModel.bookmarkDetail.isArchived ? "Unarchive Bookmark" : "Archive bookmark")
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

    @ViewBuilder
    func JumpButton(containerHeight: Double) -> some View {
        Button(action: {
            let maxOffset = webViewHeight - containerHeight
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
}

#Preview {
    NavigationView {
        ArticleReaderLegacyView(
            bookmarkId: "123",
            useNativeWebView: .constant(false),
            viewModel: .init(MockUseCaseFactory())
        )
    }
}
