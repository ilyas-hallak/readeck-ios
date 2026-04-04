//
//  OfflineImageDebugView.swift
//  readeck
//
//  Debug view to diagnose offline image loading issues
//

import SwiftUI
import Kingfisher

struct OfflineImageDebugView: View {
    let bookmarkId: String

    @State private var debugInfo = DebugInfo()
    @EnvironmentObject private var appSettings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Offline Image Debug")
                    .font(.title)
                    .padding()

                Group {
                    DebugSection("Network Status") {
                        InfoRow(label: "Connected", value: "\(appSettings.isNetworkConnected)")
                    }

                    DebugSection("Cached Article") {
                        InfoRow(label: "Has Cache", value: "\(debugInfo.hasCachedHTML)")
                        InfoRow(label: "HTML Size", value: debugInfo.htmlSize)
                        InfoRow(label: "Base64 Images", value: "\(debugInfo.base64ImageCount)")
                        InfoRow(label: "HTTP Images", value: "\(debugInfo.httpImageCount)")
                    }

                    DebugSection("Hero Image Cache") {
                        InfoRow(label: "URL", value: debugInfo.heroImageURL)
                        InfoRow(label: "In Cache", value: "\(debugInfo.heroImageInCache)")
                        InfoRow(label: "Cache Key", value: debugInfo.cacheKey)
                    }

                    if !debugInfo.sampleImages.isEmpty {
                        DebugSection("Sample HTML Images") {
                            ForEach(debugInfo.sampleImages.indices, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Image \(index + 1)")
                                        .font(.caption).bold()
                                    Text(debugInfo.sampleImages[index])
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Button("Run Diagnostics") {
                    Task {
                        await runDiagnostics()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .task {
            await runDiagnostics()
        }
    }

    private func runDiagnostics() async {
        let offlineCache = OfflineCacheRepository()

        // Check cached HTML
        if let cachedHTML = offlineCache.getCachedArticle(id: bookmarkId) {
            debugInfo.hasCachedHTML = true
            debugInfo.htmlSize = ByteCountFormatter.string(fromByteCount: Int64(cachedHTML.utf8.count), countStyle: .file)

            // Count Base64 images
            debugInfo.base64ImageCount = countMatches(in: cachedHTML, pattern: #"src="data:image/"#)

            // Count HTTP images
            debugInfo.httpImageCount = countMatches(in: cachedHTML, pattern: #"src="https?://"#)

            // Extract sample image URLs
            debugInfo.sampleImages = extractSampleImages(from: cachedHTML)
        }

        // Check hero image cache
        do {
            let bookmarkDetail = try await DefaultUseCaseFactory.shared.makeGetBookmarkUseCase().execute(id: bookmarkId)

            if !bookmarkDetail.imageUrl.isEmpty, let url = URL(string: bookmarkDetail.imageUrl) {
                debugInfo.heroImageURL = bookmarkDetail.imageUrl
                debugInfo.cacheKey = url.cacheKey

                // Check if image is in Kingfisher cache
                let isCached = await withCheckedContinuation { continuation in
                    KingfisherManager.shared.cache.retrieveImage(forKey: url.cacheKey) { result in
                        switch result {
                        case .success(let cacheResult):
                            continuation.resume(returning: cacheResult.image != nil)
                        case .failure:
                            continuation.resume(returning: false)
                        }
                    }
                }

                debugInfo.heroImageInCache = isCached
            }
        } catch {
            Logger.general.error("Error loading bookmark: \(error)")
        }
    }

    private func countMatches(in text: String, pattern: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return 0 }
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        return matches.count
    }

    private func extractSampleImages(from html: String) -> [String] {
        let pattern = #"<img[^>]+src="([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }

        let nsString = html as NSString
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))

        return matches.prefix(3).compactMap { match in
            guard match.numberOfRanges >= 2 else { return nil }
            let urlRange = match.range(at: 1)
            let url = nsString.substring(with: urlRange)

            // Truncate long Base64 strings
            if url.hasPrefix("data:image/") {
                return "data:image/... (Base64, \(url.count) chars)"
            }
            return url
        }
    }

    struct DebugInfo {
        var hasCachedHTML = false
        var htmlSize = "0 KB"
        var base64ImageCount = 0
        var httpImageCount = 0
        var heroImageURL = "N/A"
        var heroImageInCache = false
        var cacheKey = "N/A"
        var sampleImages: [String] = []
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
        .padding(.vertical, 4)
    }
}

struct DebugSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.top, 8)

            content

            Divider()
        }
    }
}

#Preview {
    OfflineImageDebugView(bookmarkId: "123")
        .environmentObject(AppSettings())
}
