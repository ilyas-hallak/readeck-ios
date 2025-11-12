//
//  DebugLogViewer.swift
//  readeck
//
//  Created by Ilyas Hallak on 01.11.25.
//

import SwiftUI

struct DebugLogViewer: View {
    @State private var entries: [LogEntry] = []
    @State private var selectedLevel: LogLevel?
    @State private var selectedCategory: LogCategory?
    @State private var searchText = ""
    @State private var showShareSheet = false
    @State private var exportText = ""
    @State private var autoScroll = true
    @State private var showFilters = false
    @StateObject private var logConfig = LogConfiguration.shared

    private let logger = Logger.ui

    var body: some View {
        VStack(spacing: 0) {
            // Logging Disabled Warning
            if !logConfig.isLoggingEnabled {
                loggingDisabledBanner
            }

            // Filter Bar
            if showFilters {
                filterBar
            }

            // Log List
            if filteredEntries.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    List {
                        ForEach(filteredEntries) { entry in
                            LogEntryRow(entry: entry)
                        }
                    }
                    .listStyle(.plain)
                    .onChange(of: entries.count) { oldValue, newValue in
                        if autoScroll, let lastEntry = filteredEntries.last {
                            withAnimation {
                                proxy.scrollTo(lastEntry.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Debug Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showFilters.toggle()
                    } label: {
                        Label(
                            showFilters ? "Hide Filters" : "Show Filters",
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                    }

                    Button {
                        autoScroll.toggle()
                    } label: {
                        Label(
                            autoScroll ? "Disable Auto-Scroll" : "Enable Auto-Scroll",
                            systemImage: autoScroll ? "arrow.down.circle.fill" : "arrow.down.circle"
                        )
                    }

                    Divider()

                    Button {
                        Task {
                            await refreshLogs()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }

                    Button {
                        Task {
                            await exportLogs()
                        }
                    } label: {
                        Label("Export Logs", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button(role: .destructive) {
                        Task {
                            await clearLogs()
                        }
                    } label: {
                        Label("Clear All Logs", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search logs")
        .task {
            await refreshLogs()
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [exportText])
        }
    }

    @ViewBuilder
    private var filterBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Filters")
                    .font(.headline)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Level Filter
                    Menu {
                        Button("All Levels") {
                            selectedLevel = nil
                        }
                        Divider()
                        ForEach(LogLevel.allCases, id: \.self) { level in
                            Button {
                                selectedLevel = level
                            } label: {
                                HStack {
                                    Text(levelName(for: level))
                                    if selectedLevel == level {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text(selectedLevel != nil ? levelName(for: selectedLevel!) : "Level")
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedLevel != nil ? Color.accentColor.opacity(0.2) : Color(.systemGray5))
                        .foregroundColor(selectedLevel != nil ? .accentColor : .primary)
                        .clipShape(Capsule())
                    }

                    // Category Filter
                    Menu {
                        Button("All Categories") {
                            selectedCategory = nil
                        }
                        Divider()
                        ForEach(LogCategory.allCases, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack {
                                    Text(category.rawValue)
                                    if selectedCategory == category {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "tag")
                            Text(selectedCategory?.rawValue ?? "Category")
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory != nil ? Color.accentColor.opacity(0.2) : Color(.systemGray5))
                        .foregroundColor(selectedCategory != nil ? .accentColor : .primary)
                        .clipShape(Capsule())
                    }

                    // Clear Filters
                    if selectedLevel != nil || selectedCategory != nil {
                        Button {
                            selectedLevel = nil
                            selectedCategory = nil
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Clear")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .foregroundColor(.secondary)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var loggingDisabledBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Logging Disabled")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Enable logging in settings to capture new logs")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                logConfig.isLoggingEnabled = true
            } label: {
                Text("Enable")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Logs Found")
                .font(.title2)
                .fontWeight(.semibold)

            if !searchText.isEmpty || selectedLevel != nil || selectedCategory != nil {
                Text("Try adjusting your filters or search criteria")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    searchText = ""
                    selectedLevel = nil
                    selectedCategory = nil
                } label: {
                    Text("Clear Filters")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            } else {
                Text("Logs will appear here as they are generated")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var filteredEntries: [LogEntry] {
        var filtered = entries

        if let level = selectedLevel {
            filtered = filtered.filter { $0.level == level }
        }

        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                $0.fileName.localizedCaseInsensitiveContains(searchText) ||
                $0.function.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    private func refreshLogs() async {
        entries = await LogStore.shared.getEntries()
    }

    private func clearLogs() async {
        await LogStore.shared.clear()
        await refreshLogs()
        logger.info("Cleared all debug logs")
    }

    private func exportLogs() async {
        exportText = await LogStore.shared.exportAsText()
        showShareSheet = true
        logger.info("Exported debug logs")
    }

    private func levelName(for level: LogLevel) -> String {
        switch level.rawValue {
        case 0: return "Debug"
        case 1: return "Info"
        case 2: return "Notice"
        case 3: return "Warning"
        case 4: return "Error"
        case 5: return "Critical"
        default: return "Unknown"
        }
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Level Badge
                Text(levelName(for: entry.level))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(levelColor(for: entry.level).opacity(0.2))
                    .foregroundColor(levelColor(for: entry.level))
                    .clipShape(Capsule())

                // Category
                Text(entry.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Timestamp
                Text(entry.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }

            // Message
            Text(entry.message)
                .font(.subheadline)
                .foregroundColor(.primary)

            // Source Location
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.caption2)
                Text("\(entry.fileName):\(entry.line)")
                    .font(.caption)
                Text("•")
                    .font(.caption)
                Text(entry.function)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func levelName(for level: LogLevel) -> String {
        switch level.rawValue {
        case 0: return "DEBUG"
        case 1: return "INFO"
        case 2: return "NOTICE"
        case 3: return "WARN"
        case 4: return "ERROR"
        case 5: return "CRITICAL"
        default: return "UNKNOWN"
        }
    }

    private func levelColor(for level: LogLevel) -> Color {
        switch level.rawValue {
        case 0: return .blue
        case 1: return .green
        case 2: return .cyan
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .gray
        }
    }
}

// MARK: - Activity View (for Share Sheet)

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        DebugLogViewer()
    }
}
