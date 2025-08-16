import SwiftUI

struct LocalBookmarksSyncView: View {
    @StateObject private var syncManager = OfflineSyncManager.shared
    @StateObject private var serverConnectivity = ServerConnectivity.shared
    @State private var showSuccessMessage = false
    @State private var syncedBookmarkCount = 0
    
    let localBookmarkCount: Int
    
    init(bookmarkCount: Int) {
        self.localBookmarkCount = bookmarkCount
    }
    
    var body: some View {
        Group {
            if showSuccessMessage {
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .imageScale(.small)
                        
                        Text("\(syncedBookmarkCount) bookmark\(syncedBookmarkCount == 1 ? "" : "s") synced successfully")
                            .font(.caption2)
                            .foregroundColor(.green)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            showSuccessMessage = false
                        }
                    }
                }
            } else if localBookmarkCount > 0 || syncManager.isSyncing {
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: syncManager.isSyncing ? "arrow.triangle.2.circlepath" : "externaldrive.badge.wifi")
                            .foregroundColor(syncManager.isSyncing ? .blue : .blue)
                            .imageScale(.medium)
                        
                        if syncManager.isSyncing {
                            Text("Syncing with server...")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        } else {
                            Text("\(localBookmarkCount) bookmark\(localBookmarkCount == 1 ? "" : "s") waiting for sync")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        if !syncManager.isSyncing && localBookmarkCount > 0 {
                            Button {
                                syncedBookmarkCount = localBookmarkCount // Store count before sync
                                Task {
                                    await syncManager.syncOfflineBookmarks()
                                }
                            } label: {
                                Image(systemName: "icloud.and.arrow.up")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    if let status = syncManager.syncStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
                .animation(.easeInOut, value: syncManager.isSyncing)
                .animation(.easeInOut, value: syncManager.syncStatus)
            }
        }
        .onChange(of: syncManager.isSyncing) { _ in
            if !syncManager.isSyncing {
                // Show success message if all bookmarks are synced
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let currentCount = syncManager.getOfflineBookmarksCount()
                    if currentCount == 0 {
                        withAnimation {
                            showSuccessMessage = true
                        }
                    }
                }
            }
        }
    }
}
