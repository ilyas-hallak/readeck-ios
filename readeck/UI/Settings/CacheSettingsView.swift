import SwiftUI

struct CacheSettingsView: View {
    @State private var viewModel = CacheSettingsViewModel()

    var body: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Cache Size")
                    Text("\(viewModel.cacheSize) / \(Int(viewModel.maxCacheSize)) MB max")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Refresh") {
                    Task {
                        await viewModel.updateCacheSize()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Max Cache Size")
                    Spacer()
                    Text("\(Int(viewModel.maxCacheSize)) MB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Slider(value: $viewModel.maxCacheSize, in: 50...1200, step: 50) {
                    Text("Max Cache Size")
                }
                .onChange(of: viewModel.maxCacheSize) { _, newValue in
                    Task {
                        await viewModel.updateMaxCacheSize(newValue)
                    }
                }
            }

            Button(action: {
                viewModel.showClearAlert = true
            }) {
                HStack {
                    if viewModel.isClearing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clear Cache")
                            .foregroundColor(viewModel.isClearing ? .secondary : .red)
                        Text("Remove all cached images")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
            .disabled(viewModel.isClearing)
        } header: {
            Text("Cache Settings")
        }
        .task {
            await viewModel.loadCacheSettings()
        }
        .alert("Clear Cache", isPresented: $viewModel.showClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task {
                    await viewModel.clearCache()
                }
            }
        } message: {
            Text("This will remove all cached images. They will be downloaded again when needed.")
        }
    }
}

#Preview {
    List {
        CacheSettingsView()
    }
    .listStyle(.insetGrouped)
}
