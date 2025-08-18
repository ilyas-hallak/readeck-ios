import SwiftUI

struct LocalBookmarksSyncView: View {
    let state: OfflineBookmarkSyncState
    let onSyncTapped: () async -> Void
    
    init(state: OfflineBookmarkSyncState, onSyncTapped: @escaping () async -> Void) {
        self.state = state
        self.onSyncTapped = onSyncTapped
    }
    
    var body: some View {
        Group {
            switch state {
            case .idle:
                EmptyView()
                
            case .pending(let count):
                pendingView(count: count)
                
            case .syncing(let count, let status):
                syncingView(count: count, status: status)
                
            case .success(let syncedCount):
                successView(syncedCount: syncedCount)
                
            case .error(let message):
                errorView(message: message)
            }
        }
    }
    
    @ViewBuilder
    private func pendingView(count: Int) -> some View {
        syncContainerView {
            HStack {
                Image(systemName: "externaldrive.badge.wifi")
                    .foregroundColor(.blue)
                    .imageScale(.medium)
                
                Text("\(count) bookmark\(count == 1 ? "" : "s") waiting for sync")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    Task { await onSyncTapped() }
                } label: {
                    Image(systemName: "icloud.and.arrow.up")
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    @ViewBuilder
    private func syncingView(count: Int, status: String?) -> some View {
        syncContainerView {
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)
                        .imageScale(.medium)
                    
                    Text("Syncing with server...")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
                
                if let status = status {
                    HStack {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func successView(syncedCount: Int) -> some View {
        syncContainerView {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .imageScale(.small)
                
                Text("\(syncedCount) bookmark\(syncedCount == 1 ? "" : "s") synced successfully")
                    .font(.caption2)
                    .foregroundColor(.green)
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func errorView(message: String) -> some View {
        syncContainerView {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .imageScale(.small)
                
                Text(message)
                    .font(.caption2)
                    .foregroundColor(.orange)
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func syncContainerView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            .padding(.horizontal)
            .animation(.easeInOut, value: state)
    }
}