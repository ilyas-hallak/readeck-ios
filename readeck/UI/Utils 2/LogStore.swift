//
//  LogStore.swift
//  readeck
//
//  Created by Ilyas Hallak on 01.11.25.
//

import Foundation

// MARK: - Log Entry

struct LogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let level: LogLevel
    let category: LogCategory
    let message: String
    let file: String
    let function: String
    let line: Int

    var fileName: String {
        URL(fileURLWithPath: file).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    }

    var formattedTimestamp: String {
        DateFormatter.logTimestamp.string(from: timestamp)
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: LogLevel,
        category: LogCategory,
        message: String,
        file: String,
        function: String,
        line: Int
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.file = file
        self.function = function
        self.line = line
    }
}

// MARK: - Log Store

actor LogStore {
    static let shared = LogStore()

    private var entries: [LogEntry] = []
    private let maxEntries: Int

    private init(maxEntries: Int = 1000) {
        self.maxEntries = maxEntries
    }

    func addEntry(_ entry: LogEntry) {
        entries.append(entry)

        // Keep only the most recent entries
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    func getEntries() -> [LogEntry] {
        return entries
    }

    func getEntries(
        level: LogLevel? = nil,
        category: LogCategory? = nil,
        searchText: String? = nil
    ) -> [LogEntry] {
        var filtered = entries

        if let level = level {
            filtered = filtered.filter { $0.level == level }
        }

        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }

        if let searchText = searchText, !searchText.isEmpty {
            filtered = filtered.filter {
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                $0.fileName.localizedCaseInsensitiveContains(searchText) ||
                $0.function.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    func clear() {
        entries.removeAll()
    }

    func exportAsText() -> String {
        var text = "Readeck Debug Logs\n"
        text += "Generated: \(DateFormatter.exportTimestamp.string(from: Date()))\n"
        text += "Total Entries: \(entries.count)\n"
        text += String(repeating: "=", count: 80) + "\n\n"

        for entry in entries {
            text += "[\(entry.formattedTimestamp)] "
            text += "[\(entry.level.emoji) \(levelName(for: entry.level))] "
            text += "[\(entry.category.rawValue)] "
            text += "\(entry.fileName):\(entry.line) "
            text += "\(entry.function)\n"
            text += "  \(entry.message)\n\n"
        }

        return text
    }

    private func levelName(for level: LogLevel) -> String {
        switch level.rawValue {
        case 0: return "DEBUG"
        case 1: return "INFO"
        case 2: return "NOTICE"
        case 3: return "WARNING"
        case 4: return "ERROR"
        case 5: return "CRITICAL"
        default: return "UNKNOWN"
        }
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let exportTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
