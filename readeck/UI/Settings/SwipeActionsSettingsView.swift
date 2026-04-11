//
//  SwipeActionsSettingsView.swift
//  readeck
//

import SwiftUI

struct SwipeActionsSettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @State private var config: SwipeActionConfig = .default
    @State private var isLoaded = false

    private let saveSettingsUseCase: PSaveSettingsUseCase

    init(saveSettingsUseCase: PSaveSettingsUseCase = DefaultUseCaseFactory.shared.makeSaveSettingsUseCase()) {
        self.saveSettingsUseCase = saveSettingsUseCase
    }

    var body: some View {
        Section {
            NavigationLink {
                SwipeActionsDetailView(
                    config: $config,
                    onSave: saveConfig
                )
            } label: {
                HStack {
                    Image(systemName: "hand.draw.fill")
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading) {
                        Text("Swipe Actions")
                        Text(swipeSummary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("Gestures")
        }
        .onAppear {
            if !isLoaded {
                config = appSettings.swipeActionConfig
                isLoaded = true
            }
        }
    }

    private var swipeSummary: String {
        let left = config.leadingActions.count
        let right = config.trailingActions.count
        return "\(left) left, \(right) right"
    }

    private func saveConfig() {
        Task {
            try? await saveSettingsUseCase.execute(swipeActionConfig: config)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
}

struct SwipeActionsDetailView: View {
    @Binding var config: SwipeActionConfig
    let onSave: () -> Void
    @State private var showAddLeading = false
    @State private var showAddTrailing = false

    var body: some View {
        List {
            Section {
                ForEach(config.leadingActions) { action in
                    HStack {
                        Image(systemName: action.iconName)
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        Text(action.displayName)
                    }
                }
                .onDelete { indexSet in
                    config.leadingActions.remove(atOffsets: indexSet)
                    onSave()
                }
                .onMove { from, to in
                    config.leadingActions.move(fromOffsets: from, toOffset: to)
                    onSave()
                }

                if config.leadingActions.count < SwipeActionConfig.maxActionsPerSide,
                   !config.availableActions.isEmpty {
                    Button {
                        showAddLeading = true
                    } label: {
                        Label("Add Action", systemImage: "plus.circle")
                    }
                }
            } header: {
                Text("Left Swipe")
            } footer: {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.lefthalf.inset.filled.arrow.left")
                    Text("First action appears at the edge")
                    Image(systemName: "arrow.right")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            Section {
                ForEach(config.trailingActions) { action in
                    HStack {
                        Image(systemName: action.iconName)
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        Text(action.displayName)
                    }
                }
                .onDelete { indexSet in
                    config.trailingActions.remove(atOffsets: indexSet)
                    onSave()
                }
                .onMove { from, to in
                    config.trailingActions.move(fromOffsets: from, toOffset: to)
                    onSave()
                }

                if config.trailingActions.count < SwipeActionConfig.maxActionsPerSide,
                   !config.availableActions.isEmpty {
                    Button {
                        showAddTrailing = true
                    } label: {
                        Label("Add Action", systemImage: "plus.circle")
                    }
                }
            } header: {
                Text("Right Swipe")
            } footer: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left")
                    Text("First action appears at the edge")
                    Image(systemName: "rectangle.righthalf.inset.filled.arrow.right")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            Section {
                Button("Reset to Default") {
                    config = .default
                    onSave()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Swipe Actions")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(.active))
        .sheet(isPresented: $showAddLeading) {
            addActionSheet(for: .leading)
        }
        .sheet(isPresented: $showAddTrailing) {
            addActionSheet(for: .trailing)
        }
    }

    enum Side {
        case leading, trailing
    }

    @ViewBuilder
    private func addActionSheet(for side: Side) -> some View {
        NavigationStack {
            List {
                ForEach(config.availableActions) { action in
                    Button {
                        switch side {
                        case .leading:
                            config.leadingActions.append(action)
                        case .trailing:
                            config.trailingActions.append(action)
                        }
                        onSave()
                        showAddLeading = false
                        showAddTrailing = false
                    } label: {
                        HStack {
                            Image(systemName: action.iconName)
                                .foregroundColor(.accentColor)
                                .frame(width: 24)
                            Text(action.displayName)
                        }
                    }
                }
            }
            .navigationTitle("Add Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddLeading = false
                        showAddTrailing = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
