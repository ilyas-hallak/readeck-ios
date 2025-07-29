import SwiftUI

struct ShareBookmarkView: View {
    @ObservedObject var viewModel: ShareBookmarkViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo
            Image("readeck")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
                .padding(.top, 24)
                .opacity(0.9)
            // URL
            if let url = viewModel.url {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .foregroundColor(.accentColor)
                    Text(url)
                        .font(.system(size: 15, weight: .bold, design: .default))
                        .foregroundColor(.accentColor)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Titel
            TextField("Enter an optional title...", text: $viewModel.title)
                .font(.system(size: 17, weight: .medium))
                .padding(.horizontal, 10)
                .foregroundColor(.primary)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.accentColor.opacity(viewModel.title.isEmpty ? 0.12 : 0.7), lineWidth: viewModel.title.isEmpty ? 1 : 2)
                )
                .padding(.top, 20)
                .padding(.horizontal, 16)
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Label Grid
            if !viewModel.labels.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select labels")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    let pageSize = Constants.Labels.pageSize
                    let pages = stride(from: 0, to: viewModel.labels.count, by: pageSize).map {
                        Array(viewModel.labels[$0..<min($0 + pageSize, viewModel.labels.count)])
                    }
                    
                    TabView {
                        ForEach(Array(pages.enumerated()), id: \.offset) { pageIndex, labelsPage in
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                                ForEach(labelsPage, id: \.name) { label in
                                    UnifiedLabelChip(
                                        label: label.name,
                                        isSelected: viewModel.selectedLabels.contains(label.name),
                                        isRemovable: false,
                                        onTap: {
                                            if viewModel.selectedLabels.contains(label.name) {
                                                viewModel.selectedLabels.remove(label.name)
                                            } else {
                                                viewModel.selectedLabels.insert(label.name)
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
                    .padding(.top, 32)
                    .frame(minHeight: 100)                
            }

            ManualTagEntryView(
                labels: viewModel.labels,
                selectedLabels: $viewModel.selectedLabels
            )
            .padding(.top, 12)
            .padding(.horizontal, 16)

            // Status
            if let status = viewModel.statusMessage {
                Text(status.emoji + " " + status.text)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(status.isError ? .red : .green)
                    .padding(.top, 32)
                    .padding(.horizontal, 16)
            }
            Spacer()
            // Save Button
            Button(action: { viewModel.save() }) {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Save Bookmark")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .disabled(viewModel.isSaving)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear { viewModel.onAppear() }
    }
}

struct ManualTagEntryView: View {
    let labels: [BookmarkLabelDto]
    @Binding var selectedLabels: Set<String>
    @State private var manualTag: String = ""
    @State private var error: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("Add new tag...", text: $manualTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                Button(action: addTag) {
                    Text("Add")
                        .font(.system(size: 15, weight: .semibold))
                }
                .disabled(manualTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private func addTag() {
        let trimmed = manualTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let lowercased = trimmed.lowercased()
        let allExisting = Set(labels.map { $0.name.lowercased() })
        let allSelected = Set(selectedLabels.map { $0.lowercased() })
        if allExisting.contains(lowercased) || allSelected.contains(lowercased) {
            error = "Tag already exists."
        } else {
            selectedLabels.insert(trimmed)
            manualTag = ""
            error = nil
        }
    }
} 
