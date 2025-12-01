//
//  DebugMenuView.swift
//  readeck
//
//  Created by Claude on 21.11.25.
//

#if DEBUG
import SwiftUI

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings
    @StateObject private var viewModel = DebugMenuViewModel()

    var body: some View {
        NavigationView {
            List {
                // MARK: - Network Section
                Section {
                    networkSimulationToggle
                    networkStatusInfo
                } header: {
                    Text("Network Debugging")
                } footer: {
                    Text("Simulate offline mode to test offline reading features")
                }

                // MARK: - Offline Debugging Section
                Section {
                    Picker("Select Cached Bookmark", selection: $viewModel.selectedBookmarkId) {
                        Text("None").tag(nil as String?)
                        ForEach(viewModel.cachedBookmarks, id: \.id) { bookmark in
                            Text(bookmark.title.isEmpty ? bookmark.id : bookmark.title)
                                .lineLimit(1)
                                .tag(bookmark.id as String?)
                        }
                    }

                    NavigationLink {
                        OfflineImageDebugView(bookmarkId: viewModel.selectedBookmarkId ?? "")
                    } label: {
                        Label("Offline Image Diagnostics", systemImage: "photo.badge.checkmark")
                    }
                    .disabled(viewModel.selectedBookmarkId == nil)
                } header: {
                    Text("Offline Reading")
                } footer: {
                    Text("Select a cached bookmark to diagnose offline image issues")
                }

                // MARK: - Logging Section
                Section {
                    NavigationLink {
                        DebugLogViewer()
                    } label: {
                        Label("View Logs", systemImage: "doc.text.magnifyingglass")
                    }

                    Button(role: .destructive) {
                        viewModel.clearLogs()
                    } label: {
                        Label("Clear All Logs", systemImage: "trash")
                    }
                } header: {
                    Text("Logging")
                } footer: {
                    Text("View and manage application logs")
                }

                // MARK: - Data Section
                Section {
                    cacheInfo

                    Button(role: .destructive) {
                        viewModel.showResetCacheAlert = true
                    } label: {
                        Label("Clear Offline Cache", systemImage: "trash")
                    }

                    Button(role: .destructive) {
                        viewModel.showResetDatabaseAlert = true
                    } label: {
                        Label("Reset Core Data", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("⚠️ Reset Core Data will delete all local bookmarks and cache")
                }

                // MARK: - App Info Section
                Section {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build Number")
                        Spacer()
                        Text(viewModel.buildNumber)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Bundle ID")
                        Spacer()
                        Text(viewModel.bundleId)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("App Information")
                }
            }
            .navigationTitle("🛠️ Debug Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadCacheInfo()
            }
            .alert("Clear Offline Cache?", isPresented: $viewModel.showResetCacheAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    Task {
                        await viewModel.clearOfflineCache()
                    }
                }
            } message: {
                Text("This will remove all cached articles. Your bookmarks will remain.")
            }
            .alert("Reset Core Data?", isPresented: $viewModel.showResetDatabaseAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel.resetCoreData()
                }
            } message: {
                Text("⚠️ WARNING: This will delete ALL local data including bookmarks, cache, and settings. This cannot be undone!")
            }
        }
    }

    // MARK: - Subviews

    private var networkSimulationToggle: some View {
        Toggle(isOn: Binding(
            get: { !appSettings.isNetworkConnected },
            set: { isOffline in
                appSettings.isNetworkConnected = !isOffline
            }
        )) {
            HStack {
                Image(systemName: appSettings.isNetworkConnected ? "wifi" : "wifi.slash")
                    .foregroundColor(appSettings.isNetworkConnected ? .green : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Simulate Offline Mode")
                    Text(appSettings.isNetworkConnected ? "Network Connected" : "Network Disconnected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var networkStatusInfo: some View {
        HStack {
            Text("Network Status")
            Spacer()
            Label(
                appSettings.isNetworkConnected ? "Connected" : "Offline",
                systemImage: appSettings.isNetworkConnected ? "checkmark.circle.fill" : "xmark.circle.fill"
            )
            .font(.caption)
            .foregroundColor(appSettings.isNetworkConnected ? .green : .orange)
        }
    }

    private var cacheInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Cached Articles")
                Spacer()
                Text("\(viewModel.cachedArticlesCount)")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Cache Size")
                Spacer()
                Text(viewModel.cacheSize)
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await viewModel.loadCacheInfo()
        }
    }
}

@MainActor
class DebugMenuViewModel: ObservableObject {
    @Published var showResetCacheAlert = false
    @Published var showResetDatabaseAlert = false
    @Published var cachedArticlesCount = 0
    @Published var cacheSize = "0 KB"
    @Published var selectedBookmarkId: String?
    @Published var cachedBookmarks: [Bookmark] = []

    private let offlineCacheRepository = OfflineCacheRepository()
    private let coreDataManager = CoreDataManager.shared
    private let logger = Logger.general

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var bundleId: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }

    func loadCacheInfo() async {
        cachedArticlesCount = offlineCacheRepository.getCachedArticlesCount()
        cacheSize = offlineCacheRepository.getCacheSize()

        // Load cached bookmarks for diagnostics
        do {
            cachedBookmarks = try await offlineCacheRepository.getCachedBookmarks()
            // Auto-select first bookmark if available
            if selectedBookmarkId == nil, let firstBookmark = cachedBookmarks.first {
                selectedBookmarkId = firstBookmark.id
            }
        } catch {
            logger.error("Failed to load cached bookmarks: \(error.localizedDescription)")
        }
    }

    func clearOfflineCache() async {
        do {
            try await offlineCacheRepository.clearCache()
            await loadCacheInfo()
            logger.info("Offline cache cleared via Debug Menu")
        } catch {
            logger.error("Failed to clear offline cache: \(error.localizedDescription)")
        }
    }

    func clearLogs() {
        // TODO: Implement log clearing when we add persistent logging
        logger.info("Logs cleared via Debug Menu")
    }

    func resetCoreData() {
        do {
            try coreDataManager.resetDatabase()
            logger.warning("Core Data reset via Debug Menu - App restart required")

            // Show alert that restart is needed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                fatalError("Core Data has been reset. Please restart the app.")
            }
        } catch {
            logger.error("Failed to reset Core Data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Shake Gesture Detection

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(DeviceShakeViewModifier(action: action))
    }
}

#Preview {
    DebugMenuView()
        .environmentObject(AppSettings())
}
#endif
