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
        NavigationView {
            Form {
                Section(header: Text("Global Settings")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Global Minimum Level")
                            .font(.headline)
                        
                        Picker("Global Level", selection: $logConfig.globalMinLevel) {
                            ForEach(LogLevel.allCases, id: \.self) { level in
                                HStack {
                                    Text(level.emoji)
                                    Text(level.rawValue == 0 ? "Debug" : 
                                         level.rawValue == 1 ? "Info" : 
                                         level.rawValue == 2 ? "Notice" : 
                                         level.rawValue == 3 ? "Warning" : 
                                         level.rawValue == 4 ? "Error" : "Critical")
                                }
                                .tag(level)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Text("Logs below this level will be filtered out globally")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Show Performance Logs", isOn: $logConfig.showPerformanceLogs)
                    Toggle("Show Timestamps", isOn: $logConfig.showTimestamps)
                    Toggle("Include Source Location", isOn: $logConfig.includeSourceLocation)
                }
                
                Section(header: Text("Category-specific Levels")) {
                    ForEach(LogCategory.allCases, id: \.self) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(category.rawValue)
                                    .font(.headline)
                                Spacer()
                                Text(levelName(for: logConfig.getLevel(for: category)))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Picker("Level for \(category.rawValue)", selection: Binding(
                                get: { logConfig.getLevel(for: category) },
                                set: { logConfig.setLevel($0, for: category) }
                            )) {
                                ForEach(LogLevel.allCases, id: \.self) { level in
                                    HStack {
                                        Text(level.emoji)
                                        Text(levelName(for: level))
                                    }
                                    .tag(level)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Reset")) {
                    Button("Reset to Defaults") {
                        resetToDefaults()
                    }
                    .foregroundColor(.orange)
                }
                
                Section(footer: Text("Changes take effect immediately. Lower log levels include higher ones (Debug includes all, Critical includes only critical messages).")) {
                    EmptyView()
                }
            }
            .navigationTitle("Logging Configuration")
            .navigationBarTitleDisplayMode(.inline)
        }
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
        
        // Reset all category levels (this will use globalMinLevel as fallback)
        for category in LogCategory.allCases {
            logConfig.setLevel(.debug, for: category)
        }
        
        // Reset global settings
        logConfig.globalMinLevel = .debug
        logConfig.showPerformanceLogs = true
        logConfig.showTimestamps = true
        logConfig.includeSourceLocation = true
        
        logger.info("Logging configuration reset to defaults")
    }
}

#Preview {
    LoggingConfigurationView()
}
