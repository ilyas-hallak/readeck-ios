import SwiftUI

struct AddBookmarkView: View {
    @State private var viewModel = AddBookmarkViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Bookmark Details")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("URL *")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("https://example.com", text: $viewModel.url)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Titel (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Bookmark Titel", text: $viewModel.title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Section(header: Text("Labels")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Labels (durch Komma getrennt)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("work, important, later", text: $viewModel.labelsText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    if !viewModel.parsedLabels.isEmpty {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 80))
                        ], spacing: 8) {
                            ForEach(viewModel.parsedLabels, id: \.self) { label in
                                Text(label)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                Section {
                    Button("Aus Zwischenablage einfügen") {
                        viewModel.pasteFromClipboard()
                    }
                    .disabled(viewModel.clipboardURL == nil)
                    
                    if let clipboardURL = viewModel.clipboardURL {
                        Text("Zwischenablage: \(clipboardURL)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            .navigationTitle("Bookmark hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        Task {
                            await viewModel.createBookmark()
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("Bookmark wird erstellt...")
                                .font(.subheadline)
                        }
                        .padding(24)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 10)
                    }
                    .ignoresSafeArea()
                }
            }
            .alert("Erfolgreich", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Bookmark wurde erfolgreich hinzugefügt!")
            }
            .alert("Fehler", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unbekannter Fehler")
            }
        }
        .onAppear {
            viewModel.checkClipboard()
        }
    }
}

#Preview {
    AddBookmarkView()
}