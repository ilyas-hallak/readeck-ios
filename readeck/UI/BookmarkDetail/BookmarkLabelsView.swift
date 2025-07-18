import SwiftUI

struct BookmarkLabelsView: View {
    let bookmarkId: String
    @State private var viewModel: BookmarkLabelsViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(bookmarkId: String, initialLabels: [String]) {
        self.bookmarkId = bookmarkId
        self._viewModel = State(initialValue: BookmarkLabelsViewModel(initialLabels: initialLabels))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Add new label section
                addLabelSection
                
                Divider()
                    .padding(.horizontal, -16)
                
                // Current labels section
                currentLabelsSection
                
                Spacer()
            }
            .padding()
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
        }
    }
    
    private var addLabelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add new label")
                .font(.headline)
                .foregroundColor(.primary)
            
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
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.accentColor)
                        )
                }
                .disabled(viewModel.newLabelText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private var currentLabelsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Current labels")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if viewModel.currentLabels.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tag")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No labels available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80, maximum: 150))
                ], spacing: 4) {
                    ForEach(viewModel.currentLabels, id: \.self) { label in
                        LabelChip(
                            label: label,
                            onRemove: {
                                Task {
                                    await viewModel.removeLabel(from: bookmarkId, label: label)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct LabelChip: View {
    let label: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.accentColor.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

#Preview {
    BookmarkLabelsView(bookmarkId: "test-id", initialLabels: ["wichtig", "arbeit", "persönlich"])
} 
