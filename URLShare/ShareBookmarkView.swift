import SwiftUI
import CoreData

struct ShareBookmarkView: View {
    @ObservedObject var viewModel: ShareBookmarkViewModel
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: AddBookmarkFieldFocus?

    @Environment(\.managedObjectContext) private var viewContext
    
    private func dismissKeyboard() {
        NotificationCenter.default.post(name: .dismissKeyboard, object: nil)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        logoSection
                        serverStatusSection
                        urlSection
                        tagManagementSection
                            .id(AddBookmarkFieldFocus.labels)
                        titleSection
                            .id(AddBookmarkFieldFocus.title)
                        statusSection
                        Spacer(minLength: 100) // Space for button
                    }
                }
                .padding(.bottom, max(0, keyboardHeight - 120))                
                .onChange(of: focusedField) { newField, _ in
                    guard let field = newField else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(field, anchor: .center)
                        }
                    }
                }
            }
            
            saveButtonSection
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = 0
            }
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
    private var serverStatusSection: some View {
        if !viewModel.isServerReachable {
            HStack(spacing: 8) {
                Image(systemName: "wifi.exclamationmark")
                    .foregroundColor(.orange)
                Text("Server not reachable - saving locally")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
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
            .focused($focusedField, equals: .title)
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
        CoreDataTagManagementView(
            selectedLabels: viewModel.selectedLabels,
            searchText: $viewModel.searchText,
            searchFieldFocus: $focusedField,
            fetchLimit: 150,
            sortOrder: viewModel.tagSortOrder,
            availableLabelsTitle: "Most used labels",
            context: viewContext,
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
    }
    
    // MARK: - Helper Functions

    private func addCustomTag() {
        viewModel.addCustomTag(context: viewContext)
    }
}
