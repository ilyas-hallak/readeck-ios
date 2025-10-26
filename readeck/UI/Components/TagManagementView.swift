import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(
                x: bounds.minX + result.frames[index].minX,
                y: bounds.minY + result.frames[index].minY
            ), proposal: ProposedViewSize(result.frames[index].size))
        }
    }
}

struct FlowResult {
    var frames: [CGRect] = []
    var bounds: CGSize = .zero
    
    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            lineHeight = max(lineHeight, size.height)
            x += size.width + spacing
            bounds.width = max(bounds.width, x - spacing)
        }
        
        bounds.height = y + lineHeight
    }
}

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
            .autocapitalization(.none)
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
                } else if allLabels.isEmpty {
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
                    labelsScrollView
                }
            }
            .padding(.top, 8)
        }
    }
    
    @ViewBuilder
    private var labelsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(chunkedLabels, id: \.self) { rowLabels in
                    HStack(alignment: .top, spacing: 8) {
                        ForEach(rowLabels, id: \.id) { label in
                            UnifiedLabelChip(
                                label: label.name,
                                isSelected: false,
                                isRemovable: false,
                                onTap: {
                                    onToggleLabel(label.name)
                                }
                            )
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: calculateMaxHeight())
    }
    
    private var chunkedLabels: [[BookmarkLabel]] {
        let maxRows = 3
        let labelsPerRow = max(1, availableUnselectedLabels.count / maxRows + (availableUnselectedLabels.count % maxRows > 0 ? 1 : 0))
        return availableUnselectedLabels.chunked(into: labelsPerRow)
    }
    
    private var availableUnselectedLabels: [BookmarkLabel] {
        let labelsToShow = searchText.wrappedValue.isEmpty ? allLabels : filteredLabels
        return labelsToShow.filter { !selectedLabelsSet.contains($0.name) }
    }
    
    private func calculateMaxHeight() -> CGFloat {
        // Berechne Höhe für maximal 3 Reihen
        let rowHeight: CGFloat = 32 // Höhe eines Labels
        let spacing: CGFloat = 8
        let maxRows: CGFloat = 3
        return (rowHeight * maxRows) + (spacing * (maxRows - 1))
    }
    
    @ViewBuilder
    private var selectedLabels: some View {
        if !selectedLabelsSet.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Selected tags")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                FlowLayout(spacing: 8) {
                    ForEach(selectedLabelsSet.sorted(), id: \.self) { label in
                        UnifiedLabelChip(
                            label: label,
                            isSelected: true,
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

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
