import SwiftUI
import SafariServices

// PreferenceKey for scroll offset tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

// PreferenceKey for content height tracking
struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct BookmarkDetailLegacyView: View {
    let bookmarkId: String
    @Binding var useNativeWebView: Bool

    // MARK: - States

    @State private var viewModel: BookmarkDetailViewModel
    @State private var webViewHeight: CGFloat = 300
    @State private var contentEndPosition: CGFloat = 0
    @State private var initialContentEndPosition: CGFloat = 0
    @State private var showingFontSettings = false
    @State private var showingLabelsSheet = false
    @State private var showingAnnotationsSheet = false
    @State private var readingProgress: Double = 0.0
    @State private var lastSentProgress: Double = 0.0
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
        VStack(spacing: 0) {
            ProgressView(value: readingProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 3)
            GeometryReader { geometry in
                ScrollView {
                    // Invisible GeometryReader to track scroll offset
                    GeometryReader { scrollGeo in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: CGPoint(
                                x: scrollGeo.frame(in: .named("scrollView")).minX,
                                y: scrollGeo.frame(in: .named("scrollView")).minY
                            )
                        )
                    }
                    .frame(height: 0)

                    VStack(spacing: 0) {
                        ZStack(alignment: .top) {
                            headerView(width: geometry.size.width)
                            VStack(alignment: .leading, spacing: 16) {
                            Color.clear.frame(width: geometry.size.width, height: viewModel.bookmarkDetail.imageUrl.isEmpty ? 84 : headerHeight)
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
                                        let imageHeight: CGFloat = viewModel.bookmarkDetail.imageUrl.isEmpty ? 84 : headerHeight
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
                    contentEndPosition = endPosition

                    let containerHeight = geometry.size.height

                    // Update initial position if content grows (WebView still loading) or first time
                    // We always take the maximum position seen (when scrolled to top, this is total content height)
                    if endPosition > initialContentEndPosition && endPosition > containerHeight * 1.2 {
                        initialContentEndPosition = endPosition
                        print("📏 Content end position updated: \(Int(endPosition)) (container: \(Int(containerHeight)))")
                    }

                    // Calculate progress from how much the end marker has moved up
                    guard initialContentEndPosition > 0 else {
                        print("⏳ Waiting for content to load... current: \(Int(endPosition)), container: \(Int(containerHeight))")
                        return
                    }

                    let totalScrollableDistance = initialContentEndPosition - containerHeight

                    guard totalScrollableDistance > 0 else {
                        print("⚠️ Content not scrollable: initial=\(initialContentEndPosition), container=\(containerHeight)")
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

                    print("📊 Progress: \(Int(progress * 100))% | scrolled: \(Int(scrolled)) / \(Int(totalScrollableDistance)) | endPos: \(Int(endPosition))")

                    // Check if we should update: threshold OR reaching 100% for first time
                    let threshold: Double = 0.03
                    let reachedEnd = progress >= 1.0 && lastSentProgress < 1.0
                    let shouldUpdate = abs(progress - lastSentProgress) >= threshold || reachedEnd

                    if shouldUpdate {
                        print("✅ Updating progress: \(Int(lastSentProgress * 100))% → \(Int(progress * 100))%\(reachedEnd ? " [END]" : "")")
                        lastSentProgress = progress
                        readingProgress = progress
                        viewModel.debouncedUpdateReadProgress(id: bookmarkId, progress: progress, anchor: nil)
                    }
                }
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { _ in
                    // Not needed anymore, we track via ContentHeightPreferenceKey
                }
            }
        }
        .frame(maxWidth: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            #if DEBUG
            // Toggle button (left)
            ToolbarItem(placement: .navigationBarLeading) {
                if #available(iOS 26.0, *) {
                    Button(action: {
                        useNativeWebView.toggle()
                    }) {
                        Image(systemName: "waveform")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            #endif

            // Top toolbar (right)
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: {
                        showingLabelsSheet = true
                    }) {
                        Image(systemName: "tag")
                    }

                    Button(action: {
                        showingAnnotationsSheet = true
                    }) {
                        Image(systemName: "pencil.line")
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
            await viewModel.loadArticleContent(id: bookmarkId)
        }
    }
    
    // MARK: - ViewBuilder
    
    @ViewBuilder
    private func headerView(width: CGFloat) -> some View {
        if !viewModel.bookmarkDetail.imageUrl.isEmpty {
            ZStack(alignment: .bottomTrailing) {
                CachedAsyncImage(url: URL(string: viewModel.bookmarkDetail.imageUrl))
                    .aspectRatio(contentMode: .fill)
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
                withAnimation(.easeInOut(duration: 0.1)) {
                    webViewHeight = height
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: webViewHeight)
            .cornerRadius(14)
            .padding(.horizontal, 4)
            .animation(.easeInOut, value: webViewHeight)
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
                    Text(URLUtil.openUrlLabel(for: viewModel.bookmarkDetail.url))
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
    
    private var archiveSection: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Finished reading?")
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
    func JumpButton(containerHeight: CGFloat) -> some View {
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
        BookmarkDetailLegacyView(
            bookmarkId: "123",
            useNativeWebView: .constant(false),
            viewModel: .init(MockUseCaseFactory())
        )
    }
}
