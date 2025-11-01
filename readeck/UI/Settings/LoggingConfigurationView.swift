//
//  LoggingConfigurationView.swift
//  readeck
//
//  Created by Ilyas Hallak on 16.08.25.
//

import SwiftUI
import os

struct LoggingConfigurationView: View {
    @StateObject private var logConfig = LogConfiguration.shared
    private let logger = Logger.ui

    var body: some View {
        List {
            Section {
                Toggle("Enable Logging", isOn: $logConfig.isLoggingEnabled)
                    .tint(.green)
            } header: {
                Text("Logging Status")
            } footer: {
                Text("Enable logging to capture debug messages. When disabled, no logs are recorded to reduce device performance impact.")
            }

            if logConfig.isLoggingEnabled {
                Section {
                    NavigationLink {
                        GlobalLogLevelView(logConfig: logConfig)
                    } label: {
                        HStack {
                            Label("Global Log Level", systemImage: "slider.horizontal.3")
                            Spacer()
                            Text(levelName(for: logConfig.globalMinLevel))
                                .foregroundColor(.secondary)
                        }
                    }

                    Toggle("Show Performance Logs", isOn: $logConfig.showPerformanceLogs)
                    Toggle("Show Timestamps", isOn: $logConfig.showTimestamps)
                    Toggle("Include Source Location", isOn: $logConfig.includeSourceLocation)
                } header: {
                    Text("Global Settings")
                } footer: {
                    Text("Logs below the global level will be filtered out globally")
                }
            }

            if logConfig.isLoggingEnabled {
                Section {
                    ForEach(LogCategory.allCases, id: \.self) { category in
                        NavigationLink {
                            CategoryLogLevelView(category: category, logConfig: logConfig)
                        } label: {
                            HStack {
                                Text(category.rawValue)
                                Spacer()
                                Text(levelName(for: logConfig.getLevel(for: category)))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Category-specific Levels")
                } footer: {
                    Text("Configure log levels for each category individually")
                }
            }

            Section {
                Button(role: .destructive) {
                    resetToDefaults()
                } label: {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("Logging Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            logger.debug("Opened logging configuration view")
        }
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

    private func resetToDefaults() {
        logger.info("Resetting logging configuration to defaults")

        for category in LogCategory.allCases {
            logConfig.setLevel(.debug, for: category)
        }

        logConfig.globalMinLevel = .debug
        logConfig.showPerformanceLogs = true
        logConfig.showTimestamps = true
        logConfig.includeSourceLocation = true

        logger.info("Logging configuration reset to defaults")
    }
}

// MARK: - Global Log Level View

struct GlobalLogLevelView: View {
    @ObservedObject var logConfig: LogConfiguration

    var body: some View {
        List {
            ForEach(LogLevel.allCases, id: \.self) { level in
                Button {
                    logConfig.globalMinLevel = level
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(levelName(for: level))
                                .foregroundColor(.primary)
                            Text(levelDescription(for: level))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if logConfig.globalMinLevel == level {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("Global Log Level")
        .navigationBarTitleDisplayMode(.inline)
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

    private func levelDescription(for level: LogLevel) -> String {
        switch level.rawValue {
        case 0: return "Show all logs including debug information"
        case 1: return "Show informational messages and above"
        case 2: return "Show notable events and above"
        case 3: return "Show warnings and errors only"
        case 4: return "Show errors and critical issues only"
        case 5: return "Show only critical issues"
        default: return ""
        }
    }
}

// MARK: - Category Log Level View

struct CategoryLogLevelView: View {
    let category: LogCategory
    @ObservedObject var logConfig: LogConfiguration

    var body: some View {
        List {
            ForEach(LogLevel.allCases, id: \.self) { level in
                Button {
                    logConfig.setLevel(level, for: category)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(levelName(for: level))
                                .foregroundColor(.primary)
                            Text(levelDescription(for: level))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if logConfig.getLevel(for: category) == level {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle("\(category.rawValue) Logs")
        .navigationBarTitleDisplayMode(.inline)
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

    private func levelDescription(for level: LogLevel) -> String {
        switch level.rawValue {
        case 0: return "Show all logs including debug information"
        case 1: return "Show informational messages and above"
        case 2: return "Show notable events and above"
        case 3: return "Show warnings and errors only"
        case 4: return "Show errors and critical issues only"
        case 5: return "Show only critical issues"
        default: return ""
        }
    }
}

#Preview {
    NavigationStack {
        LoggingConfigurationView()
    }
}
