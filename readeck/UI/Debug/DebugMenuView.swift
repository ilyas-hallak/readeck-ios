//
//  DebugMenuView.swift
//  readeck
//
//  Created by Ilyas Hallak on 21.11.25.
//

import SwiftUI
import netfox

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSettings: AppSettings
    @StateObject private var viewModel = DebugMenuViewModel()
    @AppStorage("useNativeWebView") private var useNativeWebView = true

    var body: some View {
        NavigationView {
            List {
                // MARK: - Network Section
                Section {
                    networkSimulationToggle
                    networkStatusInfo

                    Button {
                        NFX.sharedInstance().show()
                    } label: {
                        Label("Show NetFox", systemImage: "network")
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Text("NetFox Status")
                        Spacer()
                        Text(viewModel.isNetFoxRunning ? "Running" : "Stopped")
                            .font(.caption)
                            .foregroundColor(viewModel.isNetFoxRunning ? .green : .secondary)
                    }
                } header: {
                    Text("Network Debugging")
                } footer: {
                    Text("Simulate offline mode and monitor network requests with NetFox")
                }

                // MARK: - Logging Section
                Section {
                    Toggle("Enable Logging", isOn: $viewModel.isLoggingEnabled)
                        .tint(.green)
                        .onChange(of: viewModel.isLoggingEnabled) { _, newValue in
                            viewModel.updateLoggingStatus(enabled: newValue)
                        }

                    if viewModel.isLoggingEnabled {
                        NavigationLink {
                            DebugLogViewer()
                        } label: {
                            Label("Debug Logs", systemImage: "doc.text.magnifyingglass")
                        }

                        Button(role: .destructive) {
                            viewModel.clearLogs()
                        } label: {
                            Label("Clear All Logs", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("Logging")
                } footer: {
                    if viewModel.isLoggingEnabled {
                        Text("View and manage application logs")
                    } else {
                        Text("Enable logging to capture debug messages")
                    }
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

                // MARK: - Reader Section
                if #available(iOS 26.0, *) {
                    Section {
                        Toggle("Use Native WebView", isOn: $useNativeWebView)
                    } header: {
                        Text("Reader")
                    } footer: {
                        Text("Switch between the native SwiftUI reader and the legacy WKWebView-based reader.")
                    }
                }

                // MARK: - Advanced Section
                Section {
                    NavigationLink {
                        LoggingConfigurationView()
                    } label: {
                        Label("Logging Configuration", systemImage: "slider.horizontal.3")
                    }

                    NavigationLink {
                        FontDebugView()
                    } label: {
                        Label("Font Debug", systemImage: "textformat")
                    }
                } header: {
                    Text("Advanced")
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

                    HStack {
                        Text("Build Type")
                        Spacer()
                        Text(viewModel.buildType)
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
                viewModel.checkNetFoxStatus()
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
final class DebugMenuViewModel: ObservableObject {
    @Published var showResetCacheAlert = false
    @Published var showResetDatabaseAlert = false
    @Published var cachedArticlesCount = 0
    @Published var cacheSize = "0 KB"
    @Published var selectedBookmarkId: String?
    @Published var cachedBookmarks: [Bookmark] = []
    @Published var isLoggingEnabled = false
    @Published var isNetFoxRunning = false

    private let offlineCacheRepository = OfflineCacheRepository()
    private let coreDataManager = CoreDataManager.shared
    private let logger = Logger.general
    private let logConfig = LogConfiguration.shared

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var bundleId: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }

    var buildType: String {
        if Bundle.main.isDebugBuild {
            return "Debug"
        }
        if Bundle.main.isTestFlightBuild {
            return "TestFlight"
        }
        if Bundle.main.isProduction {
            return "Production"
        }
        return "Unknown"
    }

    init() {
        isLoggingEnabled = logConfig.isLoggingEnabled
    }

    func checkNetFoxStatus() {
        // NetFox doesn't provide a direct API to check if it's running
        // We'll just assume it's running if we're in a non-production build
        isNetFoxRunning = !Bundle.main.isProduction
    }

    func updateLoggingStatus(enabled: Bool) {
        logConfig.isLoggingEnabled = enabled
        logger.info("Logging \(enabled ? "enabled" : "disabled") via Debug Menu")
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
        Task {
            await LogStore.shared.clear()
            logger.info("Logs cleared via Debug Menu")
        }
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
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
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
