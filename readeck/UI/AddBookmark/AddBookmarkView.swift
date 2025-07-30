import SwiftUI

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
                                HStack {
                                    Label("URL", systemImage: "link")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("Required")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                
                                TextField("https://example.com", text: $viewModel.url)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.URL)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .onChange(of: viewModel.url) { _, _ in
                                        viewModel.checkClipboard()
                                    }
                                
                                // Clipboard Button
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
                                Label("Title", systemImage: "note.text")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Optional: Custom title", text: $viewModel.title)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Labels Field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Labels", systemImage: "tag")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("e.g. work, important, later", text: $viewModel.labelsText)
                                    .textFieldStyle(CustomTextFieldStyle())
                                
                                // Labels Preview
                                if !viewModel.parsedLabels.isEmpty {
                                    LazyVGrid(columns: [
                                        GridItem(.adaptive(minimum: 80))
                                    ], spacing: 8) {
                                        ForEach(viewModel.parsedLabels, id: \.self) { label in
                                            Text(label)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.accentColor.opacity(0.1))
                                                .foregroundColor(.accentColor)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100) // Space for button
                    }
                }
                
                // Bottom Action Area
                VStack(spacing: 16) {
                    Divider()
                    
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
                        
                        // Cancel Button
                        Button("Cancel") {
                            dismiss()
                            viewModel.clearForm()
                        }
                        .foregroundColor(.secondary)
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
        }
        .onAppear {
            viewModel.checkClipboard()
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
