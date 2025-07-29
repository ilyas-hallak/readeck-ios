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
                // Add new label
                HStack(spacing: 12) {
                    TextField("Enter label...", text: $viewModel.newLabelText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            Task {
                                await viewModel.addLabel(to: bookmarkId, label: viewModel.newLabelText)
                            }
                        }
                    
                    Button(action: {
                        Task {
                            await viewModel.addLabel(to: bookmarkId, label: viewModel.newLabelText)
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .frame(width: 32, height: 32)
                    }
                    .disabled(viewModel.newLabelText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal)
                
                // All available labels
                if !viewModel.allLabels.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("All available tags")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        TabView {
                            ForEach(Array(viewModel.labelPages.enumerated()), id: \ .offset) { pageIndex, labelsPage in
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                                    ForEach(labelsPage.filter { !viewModel.currentLabels.contains($0.name) }, id: \ .id) { label in
                                        UnifiedLabelChip(
                                            label: label.name,
                                            isSelected: viewModel.currentLabels.contains(label.name),
                                            isRemovable: false,
                                            onTap: {
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
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        .frame(height: 180)
                        .padding(.top, -20)
                    }
                }
                
                // Current labels
                if !viewModel.currentLabels.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current labels")
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
