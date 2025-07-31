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
                // Add new label with search functionality
                VStack(spacing: 8) {
                    TextField("Search or add new tag...", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            Task {
                                await viewModel.addLabel(to: bookmarkId, label: viewModel.searchText)
                            }
                        }
                    
                    // Show custom tag suggestion if search text doesn't match existing tags
                    if !viewModel.searchText.isEmpty && !viewModel.filteredLabels.contains(where: { $0.name.lowercased() == viewModel.searchText.lowercased() }) {
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
                .padding(.horizontal)
                
                // All available labels
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(viewModel.searchText.isEmpty ? "All available tags" : "Search results")
                            .font(.headline)
                        if !viewModel.searchText.isEmpty {
                            Text("(\(viewModel.filteredLabels.count) found)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if viewModel.isInitialLoading {
                        // Loading state
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                                .padding(.vertical, 40)
                            Text("Loading tags...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                    } else if viewModel.availableLabelPages.isEmpty {
                        // Empty state
                        VStack {
                            Image(systemName: viewModel.searchText.isEmpty ? "tag" : "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 20)
                            Text(viewModel.searchText.isEmpty ? "No tags available" : "No tags found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                    } else {
                        // Content state
                        TabView {
                            ForEach(Array(viewModel.availableLabelPages.enumerated()), id: \.offset) { pageIndex, labelsPage in
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                                    ForEach(labelsPage, id: \.id) { label in
                                        UnifiedLabelChip(
                                            label: label.name,
                                            isSelected: viewModel.currentLabels.contains(label.name),
                                            isRemovable: false,
                                            onTap: {
                                                print("addLabelsUseCase")
                                                Task {
                                                    await viewModel.toggleLabel(for: bookmarkId, label: label.name)
                                                }
                                            }
                                        )
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .top)
                                .padding(.horizontal)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: viewModel.availableLabelPages.count > 1 ? .automatic : .never))
                        .frame(height: 180)
                        .padding(.top, -20)
                    }
                }
                
                // Current labels
                if !viewModel.currentLabels.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current tags")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                            ForEach(viewModel.currentLabels, id: \.self) { label in
                                UnifiedLabelChip(
                                    label: label,
                                    isSelected: true,
                                    isRemovable: true,
                                    onTap: {
                                        // No action for current labels
                                    },
                                    onRemove: {
                                        Task {
                                            await viewModel.removeLabel(from: bookmarkId, label: label)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
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
}

#Preview {
    BookmarkLabelsView(bookmarkId: "test-id", initialLabels: ["wichtig", "arbeit", "persönlich"], viewModel: .init(MockUseCaseFactory(), initialLabels: ["test"]))
}
