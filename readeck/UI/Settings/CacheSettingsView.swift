import SwiftUI
import Kingfisher

struct CacheSettingsView: View {
    @State private var cacheSize: String = "0 MB"
    @State private var maxCacheSize: Double = 200
    @State private var isClearing: Bool = false
    @State private var showClearAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Cache Settings".localized, icon: "internaldrive")
                .padding(.bottom, 4)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Cache Size")
                            .foregroundColor(.primary)
                        Text("\(cacheSize) / \(Int(maxCacheSize)) MB max")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Refresh") {
                        updateCacheSize()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Max Cache Size")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(Int(maxCacheSize)) MB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $maxCacheSize, in: 50...1200, step: 50) {
                        Text("Max Cache Size")
                    }
                    .onChange(of: maxCacheSize) { _, newValue in
                        updateMaxCacheSize(newValue)
                    }
                    .accentColor(.blue)
                }
                
                Divider()
                
                Button(action: {
                    showClearAlert = true
                }) {
                    HStack {
                        if isClearing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 24)
                        } else {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 24)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clear Cache")
                                .foregroundColor(isClearing ? .secondary : .red)
                            Text("Remove all cached images")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .disabled(isClearing)
            }
        }
        .onAppear {
            updateCacheSize()
            loadMaxCacheSize()
        }
        .alert("Clear Cache", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will remove all cached images. They will be downloaded again when needed.")
        }
    }
    
    private func updateCacheSize() {
        KingfisherManager.shared.cache.calculateDiskStorageSize { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let size):
                    let mbSize = Double(size) / (1024 * 1024)
                    self.cacheSize = String(format: "%.1f MB", mbSize)
                case .failure:
                    self.cacheSize = "Unknown"
                }
            }
        }
    }
    
    private func loadMaxCacheSize() {
        let savedSize = UserDefaults.standard.object(forKey: "KingfisherMaxCacheSize") as? UInt
        if let savedSize = savedSize {
            maxCacheSize = Double(savedSize) / (1024 * 1024)
            KingfisherManager.shared.cache.diskStorage.config.sizeLimit = savedSize
        } else {
            maxCacheSize = 200
            let defaultBytes = UInt(200 * 1024 * 1024)
            KingfisherManager.shared.cache.diskStorage.config.sizeLimit = defaultBytes
            UserDefaults.standard.set(defaultBytes, forKey: "KingfisherMaxCacheSize")
        }
    }
    
    private func updateMaxCacheSize(_ newSize: Double) {
        let bytes = UInt(newSize * 1024 * 1024)
        KingfisherManager.shared.cache.diskStorage.config.sizeLimit = bytes
        UserDefaults.standard.set(bytes, forKey: "KingfisherMaxCacheSize")
    }
    
    private func clearCache() {
        isClearing = true
        
        KingfisherManager.shared.cache.clearDiskCache {
            DispatchQueue.main.async {
                self.isClearing = false
                self.updateCacheSize()
            }
        }
        
        KingfisherManager.shared.cache.clearMemoryCache()
    }
}

#Preview {
    CacheSettingsView()
        .cardStyle()
        .padding()
}