import SwiftUI

struct BookmarkLabelsView: View {
    let bookmarkId: String
    @State private var viewModel: BookmarkLabelsViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(bookmarkId: String, initialLabels: [String], viewModel: BookmarkLabelsViewModel? = nil) {
        self.bookmarkId = bookmarkId
        self._viewModel = State(initialValue: viewModel ?? BookmarkLabelsViewModel(initialLabels: initialLabels))
        
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.primary)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.primary).withAlphaComponent(0.2)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                searchSection
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
            .task {
                await viewModel.loadAllLabels()
            }
            .ignoresSafeArea(.keyboard)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var searchSection: some View {
        VStack(spacing: 8) {
            searchField
            customTagSuggestion
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var searchField: some View {
        TextField("Search or add new tag...", text: $viewModel.searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onSubmit {
                Task {
                    await viewModel.addLabel(to: bookmarkId, label: viewModel.searchText)
                }
            }
    }
    
    @ViewBuilder
    private var customTagSuggestion: some View {
        if !viewModel.searchText.isEmpty && 
           !viewModel.filteredLabels.contains(where: { $0.name.lowercased() == viewModel.searchText.lowercased() }) {
            HStack {
                Text("Add new tag:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.searchText)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Button(action: {
                    Task {
                        await viewModel.addLabel(to: bookmarkId, label: viewModel.searchText)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                        Text("Add")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    @ViewBuilder
    private var availableLabelsSection: some View {
        TagManagementView(
            allLabels: viewModel.allLabels,
            selectedLabels: Set(viewModel.currentLabels),
            searchText: $viewModel.searchText,
            isLabelsLoading: viewModel.isInitialLoading,
            availableLabelPages: viewModel.availableLabelPages,
            filteredLabels: viewModel.filteredLabels,
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
    }
}

#Preview {
    BookmarkLabelsView(bookmarkId: "test-id", initialLabels: ["wichtig", "arbeit", "persönlich"], viewModel: .init(MockUseCaseFactory(), initialLabels: ["test"]))
}
