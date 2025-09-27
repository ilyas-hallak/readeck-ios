import SwiftUI
import SafariServices
import Combine

struct BookmarkDetailView: View {
    let bookmarkId: String
    
    // MARK: - States
    
    @State private var viewModel: BookmarkDetailViewModel
    @State private var webViewHeight: CGFloat = 300
    @State private var showingFontSettings = false
    @State private var showingLabelsSheet = false
    @State private var readingProgress: Double = 0.0
    @State private var scrollViewHeight: CGFloat = 1
    @State private var showJumpToProgressButton: Bool = false
    @State private var scrollPosition = ScrollPosition(edge: .top)
    @State private var showingImageViewer = false
    
    // MARK: - Envs
    
    @EnvironmentObject var playerUIState: PlayerUIState
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss
    
    private let headerHeight: CGFloat = 360
    
    init(bookmarkId: String, viewModel: BookmarkDetailViewModel = BookmarkDetailViewModel(), webViewHeight: CGFloat = 300, showingFontSettings: Bool = false, showingLabelsSheet: Bool = false, playerUIState: PlayerUIState = .init()) {
        self.bookmarkId = bookmarkId
        self.viewModel = viewModel
        self.webViewHeight = webViewHeight
        self.showingFontSettings = showingFontSettings
        self.showingLabelsSheet = showingLabelsSheet
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: readingProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 3)
            GeometryReader { outerGeo in
                ScrollView {
                    VStack(spacing: 0) {
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self,
                                             value: geo.frame(in: .named("scroll")).minY)
                        }
                        .frame(height: 0)
                        ZStack(alignment: .top) {
                            headerView(geometry: outerGeo)
                            VStack(alignment: .leading, spacing: 16) {
                                Color.clear.frame(height: viewModel.bookmarkDetail.imageUrl.isEmpty ? 84 : headerHeight)
                                titleSection
                                Divider().padding(.horizontal)
                                if showJumpToProgressButton {
                                    JumpButton()
                                }
                                if let settings = viewModel.settings, !viewModel.articleContent.isEmpty {
                                    WebView(htmlContent: viewModel.articleContent, settings: settings, onHeightChange: { height in
                                        if webViewHeight != height {
                                            webViewHeight = height
                                        }
                                    })
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
                                            Text((URLUtil.extractDomain(from: "open " + viewModel.bookmarkDetail.url) ?? "Open original page"))
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
                        }
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    scrollViewHeight = outerGeo.size.height
                    let maxOffset = webViewHeight - scrollViewHeight
                    let rawProgress = -offset / (maxOffset != 0 ? maxOffset : 1)
                    let progress = min(max(rawProgress, 0), 1)
                    readingProgress = progress                    
                    viewModel.debouncedUpdateReadProgress(id: bookmarkId, progress: progress, anchor: nil)
                }
                .ignoresSafeArea(edges: .top)
                .scrollPosition($scrollPosition)
            }
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
        .onChange(of: viewModel.readProgress) { _, progress in
            showJumpToProgressButton = progress > 0 && progress < 100
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
                    CachedAsyncImage(url: URL(string: viewModel.bookmarkDetail.imageUrl))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: headerHeight + (offset > 0 ? offset : 0))
                        .clipped()
                        .offset(y: (offset > 0 ? -offset : 0))                        
                    
                    // Tap area and zoom icon
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
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
                    }
                    .frame(height: headerHeight + (offset > 0 ? offset : 0))
                    .offset(y: (offset > 0 ? -offset : 0))
                }
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
            .frame(height: webViewHeight)
            .cornerRadius(14)
            .padding(.horizontal)
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
                    Text((URLUtil.extractDomain(from: viewModel.bookmarkDetail.url) ?? "Open original page") + " open")
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
    func JumpButton() -> some View {
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
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

#Preview {
    NavigationView {
        BookmarkDetailView(bookmarkId: "123",
                           viewModel: .init(MockUseCaseFactory()),
                           webViewHeight: 300,
                           showingFontSettings: false,
                           showingLabelsSheet: false,
                           playerUIState: .init())
    }
}
