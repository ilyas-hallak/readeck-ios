import SwiftUI

enum AddBookmarkFieldFocus {
    case url
    case labels
    case title
}

struct FocusModifier: ViewModifier {
    let focusBinding: FocusState<AddBookmarkFieldFocus?>.Binding?
    let field: AddBookmarkFieldFocus
    
    func body(content: Content) -> some View {
        if let binding = focusBinding {
            content.focused(binding, equals: field)
        } else {
            content
        }
    }
}

struct TagManagementView: View {
    
    // MARK: - Properties
    
    let allLabels: [BookmarkLabel]
    let selectedLabelsSet: Set<String>
    let searchText: Binding<String>
    let isLabelsLoading: Bool
    let availableLabelPages: [[BookmarkLabel]]
    let filteredLabels: [BookmarkLabel]
    let searchFieldFocus: FocusState<AddBookmarkFieldFocus?>.Binding?
    
    // MARK: - Callbacks
    
    let onAddCustomTag: () -> Void
    let onToggleLabel: (String) -> Void
    let onRemoveLabel: (String) -> Void
    
    // MARK: - Initialization
    
    init(
        allLabels: [BookmarkLabel],
        selectedLabels: Set<String>,
        searchText: Binding<String>,
        isLabelsLoading: Bool,
        availableLabelPages: [[BookmarkLabel]],
        filteredLabels: [BookmarkLabel],
        searchFieldFocus: FocusState<AddBookmarkFieldFocus?>.Binding? = nil,
        onAddCustomTag: @escaping () -> Void,
        onToggleLabel: @escaping (String) -> Void,
        onRemoveLabel: @escaping (String) -> Void
    ) {
        self.allLabels = allLabels
        self.selectedLabelsSet = selectedLabels
        self.searchText = searchText
        self.isLabelsLoading = isLabelsLoading
        self.availableLabelPages = availableLabelPages
        self.filteredLabels = filteredLabels
        self.searchFieldFocus = searchFieldFocus
        self.onAddCustomTag = onAddCustomTag
        self.onToggleLabel = onToggleLabel
        self.onRemoveLabel = onRemoveLabel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            searchField
            customTagSuggestion
            availableLabels
            selectedLabels
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var searchField: some View {
        TextField("Search or add new tag...", text: searchText)
            .textFieldStyle(CustomTextFieldStyle())
            .keyboardType(.default)
            .autocorrectionDisabled(true)
            .onSubmit {
                onAddCustomTag()
            }
            .modifier(FocusModifier(focusBinding: searchFieldFocus, field: .labels))
    }
    
    @ViewBuilder
    private var customTagSuggestion: some View {
        if !searchText.wrappedValue.isEmpty && 
           !allLabels.contains(where: { $0.name.lowercased() == searchText.wrappedValue.lowercased() }) && 
           !selectedLabelsSet.contains(searchText.wrappedValue) {
            HStack {
                Text("Add new tag:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(searchText.wrappedValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Button(action: onAddCustomTag) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        Text("Add")
                            .font(.subheadline)
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
    }
    
    @ViewBuilder
    private var availableLabels: some View {
        if !allLabels.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(searchText.wrappedValue.isEmpty ? "Available tags" : "Search results")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if !searchText.wrappedValue.isEmpty {
                        Text("(\(filteredLabels.count) found)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                if isLabelsLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else if availableLabelPages.isEmpty {
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
                    labelsTabView
                }
            }
            .padding(.top, 8)
        }
    }
    
    @ViewBuilder
    private var labelsTabView: some View {
        TabView {
            ForEach(Array(availableLabelPages.enumerated()), id: \.offset) { pageIndex, labelsPage in
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                    ForEach(labelsPage, id: \.id) { label in
                        UnifiedLabelChip(
                            label: label.name,
                            isSelected: selectedLabelsSet.contains(label.name),
                            isRemovable: false,
                            onTap: {
                                onToggleLabel(label.name)
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: availableLabelPages.count > 1 ? .automatic : .never))
        .frame(height: 180)
        .padding(.top, 10)
    }
    
    @ViewBuilder
    private var selectedLabels: some View {
        if !selectedLabelsSet.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Selected tags")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                    ForEach(Array(selectedLabelsSet), id: \.self) { label in
                        UnifiedLabelChip(
                            label: label,
                            isSelected: false,
                            isRemovable: true,
                            onTap: {
                                // No action for selected labels
                            },
                            onRemove: {
                                onRemoveLabel(label)
                            }
                        )
                    }
                }
            }
            .padding(.top, 8)
        }
    }
}
