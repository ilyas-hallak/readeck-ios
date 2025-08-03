import SwiftUI

struct ShareBookmarkView: View {
    @ObservedObject var viewModel: ShareBookmarkViewModel
    @State private var keyboardHeight: CGFloat = 0
    @State private var shouldScrollToTitle = false
    
    private func dismissKeyboard() {
        NotificationCenter.default.post(name: NSNotification.Name("DismissKeyboard"), object: nil)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        logoSection
                        urlSection
                        tagManagementSection
                        titleSection
                            .id("titleField")
                        statusSection
                        Spacer(minLength: 100) // Space for button
                    }
                }
                .padding(.bottom, keyboardHeight / 2)                
                .onChange(of: shouldScrollToTitle) { shouldScroll, _ in
                    if shouldScroll {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("titleField", anchor: .center)
                        }
                        shouldScrollToTitle = false
                    }
                }
            }
            
            saveButtonSection
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
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
                // Scroll to title field when keyboard appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    shouldScrollToTitle = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var logoSection: some View {
        Image("readeck")
            .resizable()
            .scaledToFit()
            .frame(height: 40)
            .padding(.top, 24)
            .opacity(0.9)
    }
    
    @ViewBuilder
    private var urlSection: some View {
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
    }
    
    @ViewBuilder
    private var titleSection: some View {
        TextField("Enter an optional title...", text: $viewModel.title)
            .textFieldStyle(CustomTextFieldStyle())
            .font(.system(size: 17, weight: .medium))
            .padding(.horizontal, 10)
            .foregroundColor(.primary)
            .frame(height: 38)
            .padding(.top, 20)
            .padding(.horizontal, 4)
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
    }
    
    @ViewBuilder
    private var tagManagementSection: some View {
        if !viewModel.labels.isEmpty {
            TagManagementView(
                allLabels: convertToBookmarkLabels(viewModel.labels),
                selectedLabels: viewModel.selectedLabels,
                searchText: $viewModel.searchText,
                isLabelsLoading: false,
                availableLabelPages: convertToBookmarkLabelPages(viewModel.availableLabelPages),
                filteredLabels: convertToBookmarkLabels(viewModel.filteredLabels),
                onAddCustomTag: {
                    addCustomTag()
                },
                onToggleLabel: { label in
                    if viewModel.selectedLabels.contains(label) {
                        viewModel.selectedLabels.remove(label)
                    } else {
                        viewModel.selectedLabels.insert(label)
                    }
                    viewModel.searchText = ""
                },
                onRemoveLabel: { label in
                    viewModel.selectedLabels.remove(label)
                }
            )
            .padding(.top, 20)
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private var statusSection: some View {
        if let status = viewModel.statusMessage {
            Text(status.emoji + " " + status.text)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(status.isError ? .red : .green)
                .padding(.top, 32)
                .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private var saveButtonSection: some View {
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
        .padding(.top, 16)
        .padding(.bottom, 32)
        .disabled(viewModel.isSaving)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Helper Functions
    
    private func convertToBookmarkLabels(_ dtos: [BookmarkLabelDto]) -> [BookmarkLabel] {
        return dtos.map { .init(name: $0.name, count: $0.count, href: $0.href) }
    }
    
    private func convertToBookmarkLabelPages(_ dtoPages: [[BookmarkLabelDto]]) -> [[BookmarkLabel]] {
        return dtoPages.map { convertToBookmarkLabels($0) }
    }
    
    private func addCustomTag() {
        let trimmed = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let lowercased = trimmed.lowercased()
        let allExisting = Set(viewModel.labels.map { $0.name.lowercased() })
        let allSelected = Set(viewModel.selectedLabels.map { $0.lowercased() })
        
        if allExisting.contains(lowercased) || allSelected.contains(lowercased) {
            // Tag already exists, don't add
            return
        } else {
            viewModel.selectedLabels.insert(trimmed)
            viewModel.searchText = ""
        }
    }
}
