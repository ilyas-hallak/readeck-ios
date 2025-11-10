import SwiftUI
import UIKit

struct AddBookmarkView: View {
    @State private var viewModel = AddBookmarkViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appSettings: AppSettings
    @FocusState private var focusedField: AddBookmarkFieldFocus?
    @State private var keyboardHeight: CGFloat = 0
    
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
                formContent
                bottomActionArea
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
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
        }
        .onAppear {
            viewModel.checkClipboard()
            Task {
                await viewModel.syncTags()
            }
        }
        .onDisappear {
            viewModel.clearForm()
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var formContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        urlField
                            .id("urlField")
                            .id("labelsOffset")
                        labelsField
                            .id("labelsField")
                        titleField
                            .id("titleField")
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 120)
                }
                .padding(.top, 20) // Add top padding for offset
            }
            .padding(.bottom, keyboardHeight / 2)
            .onChange(of: focusedField) { field in
                guard let field = field else { return }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        switch field {
                        case .url:
                            proxy.scrollTo("urlField", anchor: .top)
                        case .labels:
                            proxy.scrollTo("labelsOffset", anchor: .top)
                        case .title:
                            proxy.scrollTo("titleField", anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var urlField: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("https://example.com", text: $viewModel.url)
                .textFieldStyle(CustomTextFieldStyle())
                .keyboardType(.URL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .url)
                .onChange(of: viewModel.url) { _, _ in
                    viewModel.checkClipboard()
                }
            
            clipboardButton
        }
    }
    
    @ViewBuilder
    private var clipboardButton: some View {
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
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .transition(.opacity.combined(with: .move(edge: .top)))
            .padding(.top, 4)
        }
    }
    
    @ViewBuilder
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Optional: Custom title", text: $viewModel.title)
                .textFieldStyle(CustomTextFieldStyle())
                .focused($focusedField, equals: .title)
        }
    }
    
    @ViewBuilder
    private var labelsField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appSettings.tagSortOrder == .byCount ? "Sorted by usage count".localized : "Sorted alphabetically".localized)
                .font(.caption)
                .foregroundColor(.secondary)

            CoreDataTagManagementView(
                selectedLabels: viewModel.selectedLabels,
                searchText: $viewModel.searchText,
                searchFieldFocus: $focusedField,
                fetchLimit: nil,
                sortOrder: appSettings.tagSortOrder,
                context: viewContext,
                onAddCustomTag: {
                    viewModel.addCustomTag()
                },
                onToggleLabel: { label in
                    viewModel.toggleLabel(label)
                },
                onRemoveLabel: { label in
                    viewModel.removeLabel(label)
                }
            )
        }
    }
    
    @ViewBuilder
    private var bottomActionArea: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    private var saveButton: some View {
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
}

// MARK: - Custom Styles

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
