import SwiftUI
import UIKit

struct AddBookmarkView: View {
    @State private var viewModel = AddBookmarkViewModel()
    @Environment(\.dismiss) private var dismiss
    
    init(prefilledURL: String? = nil, prefilledTitle: String? = nil) {
        _viewModel = State(initialValue: AddBookmarkViewModel())
        if let url = prefilledURL {
            viewModel.url = url
        }
        if let title = prefilledTitle {
            viewModel.title = title
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Scrollable Form Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Form Fields
                        VStack(spacing: 20) {
                            // URL Field
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("https://example.com", text: $viewModel.url)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.URL)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .onChange(of: viewModel.url) { _, _ in
                                        viewModel.checkClipboard()
                                    }
                                
                                // Clipboard Button - only show if we have a URL in clipboard
                                if viewModel.showClipboardButton {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("URL in clipboard:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Text(viewModel.clipboardURL ?? "")
                                                .font(.subheadline)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 8) {
                                            Button("Paste") {
                                                viewModel.pasteFromClipboard()
                                            }
                                            .buttonStyle(SecondaryButtonStyle())
                                            
                                            Button(action: {
                                                viewModel.dismissClipboard()
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            
                            // Title Field
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Optional: Custom title", text: $viewModel.title)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Labels Field
                            VStack(alignment: .leading, spacing: 8) {
                                // Search field for tags
                                TextField("Search or add new tag...", text: $viewModel.searchText)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .onSubmit {
                                        viewModel.addCustomTag()
                                    }
                                
                                // Show custom tag suggestion if search text doesn't match existing tags
                                if !viewModel.searchText.isEmpty && !viewModel.allLabels.contains(where: { $0.name.lowercased() == viewModel.searchText.lowercased() }) && !viewModel.selectedLabels.contains(viewModel.searchText) {
                                    HStack {
                                        Text("Add new tag:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(viewModel.searchText)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Button(action: {
                                            viewModel.addCustomTag()
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
                                
                                // Available labels
                                if !viewModel.allLabels.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(viewModel.searchText.isEmpty ? "Available tags" : "Search results")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            if !viewModel.searchText.isEmpty {
                                                Text("(\(viewModel.filteredLabels.count) found)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                        
                                        if viewModel.isLabelsLoading {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .frame(maxWidth: .infinity, alignment: .center)
                                                .padding(.vertical, 20)
                                        } else if viewModel.availableLabels.isEmpty {
                                            VStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.green)
                                                Text("All tags selected")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 20)
                                        } else {
                                            // Use pagination from ViewModel
                                            TabView {
                                                ForEach(Array(viewModel.availableLabelPages.enumerated()), id: \.offset) { pageIndex, labelsPage in
                                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                                                        ForEach(labelsPage, id: \.id) { label in
                                                            UnifiedLabelChip(
                                                                label: label.name,
                                                                isSelected: viewModel.selectedLabels.contains(label.name),
                                                                isRemovable: false,
                                                                onTap: {
                                                                    viewModel.toggleLabel(label.name)
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
                                    .padding(.top, 8)
                                }
                                
                                // Selected labels
                                if !viewModel.selectedLabels.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Selected tags")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
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
                                                        viewModel.removeLabel(label)
                                                    }
                                                )
                                            }
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 120) // Space for button
                    }
                }
                
                // Bottom Action Area
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        // Save Button
                        Button(action: {
                            Task {
                                await viewModel.createBookmark()
                                if viewModel.hasCreated {
                                    dismiss()
                                }
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "bookmark.fill")
                                }
                                
                                Text(viewModel.isLoading ? "Saving..." : "Save bookmark")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(viewModel.isValid && !viewModel.isLoading ? Color.accentColor : Color.gray)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!viewModel.isValid || viewModel.isLoading)                                                
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("New Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                        viewModel.clearForm()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .onAppear {
            viewModel.checkClipboard()
        }
        .task {
            await viewModel.loadAllLabels()
        }
        .onDisappear {
            viewModel.clearForm()
        }
    }
}

// MARK: - Custom Styles

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    AddBookmarkView()
}
