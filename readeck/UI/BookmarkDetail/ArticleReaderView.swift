import SwiftUI
import SafariServices

@available(iOS 26.0, *)
struct ArticleReaderView: View {
    let bookmarkId: String
    @Binding var useNativeWebView: Bool

    // MARK: - States

    @State private var viewModel: BookmarkDetailViewModel
    @State private var webViewHeight: Double = 300
    @State private var contentEndPosition: Double = 0
    @State private var showingFontSettings = false
    @State private var showingLabelsSheet = false
    @State private var showingAnnotationsSheet = false
    @State private var readingProgress = 0.0
    @State private var showJumpToProgressButton = false
    @State private var scrollPosition = ScrollPosition(edge: .top)
    @State private var showingImageViewer = false
    @State private var showingErrorAlert = false
    @State private var showingSummarySheet = false
    @State private var isToolbarVisible: Bool = true
    @State private var scrollTracker = ScrollTracker()

    // MARK: - Envs

    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss

    private let headerHeight: Double = 360

    init(bookmarkId: String, useNativeWebView: Binding<Bool>, viewModel: BookmarkDetailViewModel = BookmarkDetailViewModel()) {
        self.bookmarkId = bookmarkId
        self._useNativeWebView = useNativeWebView
        self.viewModel = viewModel
    }

    var body: some View {
        mainView
            .background(nativeBackgroundColor)
    }

    private var mainView: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .toolbar(isToolbarVisible ? .visible : .hidden, for: .navigationBar)
            .animation(.easeInOut(duration: 0.25), value: isToolbarVisible)
            .sheet(isPresented: $showingFontSettings) {
                fontSettingsSheet
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
            .sheet(isPresented: $showingSummarySheet) {
                ArticleSummarySheet(
                    articleContent: viewModel.articleContent,
                    summarizeUseCase: DefaultUseCaseFactory.shared.makeSummarizeArticleUseCase()
                )
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
            .onChange(of: showingAnnotationsSheet) { _, isShowing in
                if !isShowing {
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
                await viewModel.loadArticleContent(id: bookmarkId)
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            // Progress bar at top
            if !(viewModel.settings?.hideProgressBar ?? false) {
                ProgressView(value: readingProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 3)
            }

            // Main scroll content
            scrollViewContent
                .overlay(alignment: .bottomTrailing) {
                    if viewModel.isLoadingArticle == false && viewModel.isLoading == false {
                        if readingProgress >= 0.9 {
                            floatingActionButtons
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: readingProgress >= 0.9)
        }
    }

    private var floatingActionButtons: some View {
        GlassEffectContainer(spacing: 52.0) {
            HStack(spacing: 52.0) {
                Button(action: {
                    Task {
                        await viewModel.toggleFavorite(id: bookmarkId)
                    }
                }) {
                    Image(systemName: viewModel.bookmarkDetail.isMarked ? "star.fill" : "star")
                        .foregroundStyle(viewModel.bookmarkDetail.isMarked ? .yellow : .primary)
                        .frame(width: 52.0, height: 52.0)
                        .font(.system(size: 31))
                }
                .disabled(viewModel.isLoading)
                .glassEffect()

                Button(action: {
                    Task {
                        await viewModel.archiveBookmark(id: bookmarkId, isArchive: !viewModel.bookmarkDetail.isArchived)
                    }
                }) {
                    Image(systemName: viewModel.bookmarkDetail.isArchived ? "checkmark.circle" : "archivebox")
                        .frame(width: 52.0, height: 52.0)
                        .font(.system(size: 31))
                }
                .disabled(viewModel.isLoading)
                .glassEffect()
                .offset(x: -52.0, y: 0.0)
            }
        }
        .padding(.trailing, 1)
        .padding(.bottom, 10)
    }

    private var scrollViewContent: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        if !(viewModel.settings?.hideHeroImage ?? false) {
                            headerView(width: geometry.size.width)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            Color.clear.frame(width: geometry.size.width, height: (viewModel.bookmarkDetail.imageUrl.isEmpty || (viewModel.settings?.hideHeroImage ?? false)) ? 84 : headerHeight)

                            titleSection

                            Divider().padding(.horizontal)

                            if showJumpToProgressButton {
                                jumpButton(containerHeight: geometry.size.height)
                            }

                            // Article content (WebView)
                            articleContent
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
            .ignoresSafeArea(edges: [.top, .bottom])
            .scrollPosition($scrollPosition)
            .onPreferenceChange(ContentHeightPreferenceKey.self) { endPosition in
                contentEndPosition = endPosition

                let result = scrollTracker.update(endPosition: endPosition, containerHeight: geometry.size.height)

                if let progress = result.readingProgress {
                    readingProgress = progress

                    if result.shouldUpdateProgress {
                        viewModel.debouncedUpdateReadProgress(id: bookmarkId, progress: progress, anchor: nil)
                    }
                }

                if let visible = result.isToolbarVisible {
                    isToolbarVisible = visible
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if Bundle.main.isDebugBuild {
            // Toggle button (left)
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    useNativeWebView.toggle()
                }) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.accentColor)
                }
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

                if viewModel.hasAnnotations {
                    Button(action: {
                        showingAnnotationsSheet = true
                    }) {
                        Image(systemName: "pencil.line")
                    }
                }

                Button(action: {
                    showingFontSettings = true
                }) {
                    Image(systemName: "textformat")
                }
            }
        }
    }

    private var fontSettingsSheet: some View {
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

    // MARK: - ViewBuilder

    @ViewBuilder
    private func headerView(width: Double) -> some View {
        if !viewModel.bookmarkDetail.imageUrl.isEmpty {
            ZStack(alignment: .bottomTrailing) {
                // Background blur for images that don't fill
                CachedAsyncImage(
                    url: URL(string: viewModel.bookmarkDetail.imageUrl),
                    cacheKey: "bookmark-\(viewModel.bookmarkDetail.id)-hero"
                )
                    .scaledToFill()
                    .frame(width: width, height: headerHeight)
                    .blur(radius: 30)
                    .clipped()

                // Main image with fit
                CachedAsyncImage(
                    url: URL(string: viewModel.bookmarkDetail.imageUrl),
                    cacheKey: "bookmark-\(viewModel.bookmarkDetail.id)-hero"
                )
                    .scaledToFit()
                    .frame(width: width, height: headerHeight)

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
            .frame(width: width, height: headerHeight)
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
        }
        .padding(.horizontal)
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
            if !(viewModel.settings?.hideWordCount ?? false) {
                metaRow(icon: "textformat", text: "\(viewModel.bookmarkDetail.wordCount ?? 0) words • \(viewModel.bookmarkDetail.readingTime ?? 0) min read")
            }

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

            if SummarizeArticleUseCase.isAvailable && !viewModel.articleContent.isEmpty {
                metaRow(icon: "sparkles") {
                    Button(action: {
                        showingSummarySheet = true
                    }) {
                        Text("Summarize".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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

    private var nativeBackgroundColor: Color {
        let theme = viewModel.settings?.readerColorTheme ?? .system
        switch theme {
        case .system: return Color(.systemBackground)
        case .custom:
            if let hex = viewModel.settings?.customBackgroundColor {
                return Color(hex: hex)
            }
            return Color(.systemBackground)
        default:
            return theme.backgroundColor ?? Color(.systemBackground)
        }
    }

    private var nativeTextColor: Color {
        let theme = viewModel.settings?.readerColorTheme ?? .system
        switch theme {
        case .system: return .primary
        case .custom:
            if let hex = viewModel.settings?.customTextColor {
                return Color(hex: hex)
            }
            return .primary
        default:
            return theme.textColor ?? .primary
        }
    }

    private var nativeSecondaryTextColor: Color {
        nativeTextColor.opacity(0.6)
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
                        let imageHeight: Double = viewModel.bookmarkDetail.imageUrl.isEmpty ? 84 : headerHeight
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

    private func jumpButton(containerHeight: Double) -> some View {
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
}

#Preview {
    if #available(iOS 26.0, *) {
        NavigationView {
            ArticleReaderView(
                bookmarkId: "123",
                useNativeWebView: .constant(true),
                viewModel: .init(MockUseCaseFactory())
            )
        }
    }
}
