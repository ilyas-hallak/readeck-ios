import SwiftUI

struct BookmarkLabelsView: View {
    let bookmarkId: String
    @State private var viewModel: BookmarkLabelsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appSettings: AppSettings
    
    init(bookmarkId: String, initialLabels: [String], viewModel: BookmarkLabelsViewModel? = nil) {
        self.bookmarkId = bookmarkId
        self._viewModel = State(initialValue: viewModel ?? BookmarkLabelsViewModel(initialLabels: initialLabels))
        
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.primary)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.primary).withAlphaComponent(0.2)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                availableLabelsSection
                Spacer()
            }
            .padding(.vertical)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Manage Labels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .ignoresSafeArea(.keyboard)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .onAppear {
                Task {
                    await viewModel.syncTags()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    
    
    @ViewBuilder
    private var availableLabelsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appSettings.tagSortOrder == .byCount ? "Sorted by usage count".localized : "Sorted alphabetically".localized)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            CoreDataTagManagementView(
                selectedLabels: Set(viewModel.currentLabels),
                searchText: $viewModel.searchText,
                fetchLimit: nil,
                sortOrder: appSettings.tagSortOrder,
                context: viewContext,
                onAddCustomTag: {
                    Task {
                        await viewModel.addLabel(to: bookmarkId, label: viewModel.searchText)
                    }
                },
                onToggleLabel: { label in
                    Task {
                        await viewModel.toggleLabel(for: bookmarkId, label: label)
                    }
                },
                onRemoveLabel: { label in
                    Task {
                        await viewModel.removeLabel(from: bookmarkId, label: label)
                    }
                }
            )
            .padding(.horizontal)
        }
    }
}

#Preview {
    BookmarkLabelsView(bookmarkId: "test-id", initialLabels: ["wichtig", "arbeit", "persönlich"], viewModel: .init(MockUseCaseFactory(), initialLabels: ["test"]))
}
