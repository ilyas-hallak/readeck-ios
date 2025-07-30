import SwiftUI

struct ShareBookmarkView: View {
    @ObservedObject var viewModel: ShareBookmarkViewModel
    
    private func dismissKeyboard() {
        NotificationCenter.default.post(name: NSNotification.Name("DismissKeyboard"), object: nil)
    }
    
    var body: some View {
        ScrollView {
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
                // Title
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
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                dismissKeyboard()
                            }
                        }
                    }
                
                // Manual tag entry (always visible)
                ManualTagEntryView(
                    labels: viewModel.labels,
                    selectedLabels: $viewModel.selectedLabels,
                    searchText: $viewModel.searchText
                )
                .padding(.top, 20)
                .padding(.horizontal, 16)
                
                // Unified Labels Section
                if !viewModel.labels.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Available labels")
                                .font(.headline)
                            if !viewModel.searchText.isEmpty {
                                Text("(\(viewModel.filteredLabels.count) found)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        if viewModel.availableLabels.isEmpty {
                            // All labels are selected
                            VStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                                    .padding(.vertical, 20)
                                Text("All labels selected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                        } else {
                            // Use pagination from ViewModel
                            TabView {
                                ForEach(Array(viewModel.availableLabelPages.enumerated()), id: \.offset) { pageIndex, labelsPage in
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
                                                    viewModel.searchText = ""
                                                }
                                            )
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .top)
                                    .padding(.horizontal)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: viewModel.availableLabelPages.count > 1 ? .automatic : .never))
                            .frame(height: 180)
                            .padding(.top, -20)
                        }
                    }
                    .padding(.top, 32)
                    .frame(minHeight: 100)                
                }

                // Current selected labels
                if !viewModel.selectedLabels.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected tags")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                            ForEach(Array(viewModel.selectedLabels), id: \.self) { label in
                                UnifiedLabelChip(
                                    label: label,
                                    isSelected: false,
                                    isRemovable: true,
                                    onTap: {
                                        // No action for selected labels
                                    },
                                    onRemove: {
                                        viewModel.selectedLabels.remove(label)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                }

                // Status
                if let status = viewModel.statusMessage {
                    Text(status.emoji + " " + status.text)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(status.isError ? .red : .green)
                        .padding(.top, 32)
                        .padding(.horizontal, 16)
                }
                
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
                .padding(.top, 32)
                .padding(.bottom, 32)
                .disabled(viewModel.isSaving)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear { viewModel.onAppear() }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    // Fallback for extensions: tap anywhere to dismiss keyboard
                    dismissKeyboard()
                }
        )
    }
}

struct ManualTagEntryView: View {
    let labels: [BookmarkLabelDto]
    @Binding var selectedLabels: Set<String>
    @Binding var searchText: String
    @State private var error: String? = nil
    
    private func dismissKeyboard() {
        NotificationCenter.default.post(name: NSNotification.Name("DismissKeyboard"), object: nil)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Search field
            TextField("Search or add new tag...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            dismissKeyboard()
                        }
                    }
                }
                .onSubmit {
                    addCustomTag()
                }
            
            // Show custom tag suggestion if search text doesn't match existing tags
            if !searchText.isEmpty && !labels.contains(where: { $0.name.lowercased() == searchText.lowercased() }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add new tag:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(searchText)
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    Button(action: addCustomTag) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Add")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(10)
            }
            
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    // Fallback for extensions: tap anywhere to dismiss keyboard
                    dismissKeyboard()
                }
        )
    }
    
    private func addCustomTag() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let lowercased = trimmed.lowercased()
        let allExisting = Set(labels.map { $0.name.lowercased() })
        let allSelected = Set(selectedLabels.map { $0.lowercased() })
        
        if allExisting.contains(lowercased) || allSelected.contains(lowercased) {
            error = "Tag already exists."
        } else {
            selectedLabels.insert(trimmed)
            searchText = ""
            error = nil
        }
    }
} 
