import SwiftUI
import CoreData

struct CoreDataTagManagementView: View {

    // MARK: - Properties

    let selectedLabelsSet: Set<String>
    let searchText: Binding<String>
    let searchFieldFocus: FocusState<AddBookmarkFieldFocus?>.Binding?
    let sortOrder: TagSortOrder
    let availableLabelsTitle: String?
    let context: NSManagedObjectContext

    // MARK: - Callbacks

    let onAddCustomTag: () -> Void
    let onToggleLabel: (String) -> Void
    let onRemoveLabel: (String) -> Void

    // MARK: - FetchRequest

    @FetchRequest
    private var tagEntities: FetchedResults<TagEntity>

    // MARK: - Search State

    @State private var searchResults: [TagEntity] = []
    @State private var isSearchActive: Bool = false

    // MARK: - Initialization

    init(
        selectedLabels: Set<String>,
        searchText: Binding<String>,
        searchFieldFocus: FocusState<AddBookmarkFieldFocus?>.Binding? = nil,
        fetchLimit: Int? = nil,
        sortOrder: TagSortOrder = .byCount,
        availableLabelsTitle: String? = nil,
        context: NSManagedObjectContext,
        onAddCustomTag: @escaping () -> Void,
        onToggleLabel: @escaping (String) -> Void,
        onRemoveLabel: @escaping (String) -> Void
    ) {
        self.selectedLabelsSet = selectedLabels
        self.searchText = searchText
        self.searchFieldFocus = searchFieldFocus
        self.sortOrder = sortOrder
        self.availableLabelsTitle = availableLabelsTitle
        self.context = context
        self.onAddCustomTag = onAddCustomTag
        self.onToggleLabel = onToggleLabel
        self.onRemoveLabel = onRemoveLabel

        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()

        // Apply sort order from parameter
        let sortDescriptors: [NSSortDescriptor]
        switch sortOrder {
        case .byCount:
            sortDescriptors = [
                NSSortDescriptor(keyPath: \TagEntity.count, ascending: false),
                NSSortDescriptor(keyPath: \TagEntity.name, ascending: true)
            ]
        case .alphabetically:
            sortDescriptors = [
                NSSortDescriptor(keyPath: \TagEntity.name, ascending: true)
            ]
        }
        fetchRequest.sortDescriptors = sortDescriptors

        if let limit = fetchLimit {
            fetchRequest.fetchLimit = limit
        }
        fetchRequest.fetchBatchSize = 20

        _tagEntities = FetchRequest(
            fetchRequest: fetchRequest,
            animation: .default
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            searchField
            customTagSuggestion
            availableLabels
            selectedLabels
        }
        .onChange(of: searchText.wrappedValue) { oldValue, newValue in
            performSearch(query: newValue)
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var searchField: some View {
        TextField("Search or add new label...", text: searchText)
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
           !allTagNames.contains(where: { $0.lowercased() == searchText.wrappedValue.lowercased() }) &&
           !selectedLabelsSet.contains(searchText.wrappedValue) {
            HStack {
                Text("Add new label:")
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
        if !tagEntities.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(searchText.wrappedValue.isEmpty ? (availableLabelsTitle ?? "Available labels") : "Search results")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if !searchText.wrappedValue.isEmpty {
                        Text("(\(filteredTagsCount) found)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

                if availableUnselectedTagsCount == 0 {
                    // Show "All labels selected" only if there are actually filtered results
                    // Otherwise show "No labels found" for empty search results
                    if filteredTagsCount > 0 {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                            Text("All labels selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else if !searchText.wrappedValue.isEmpty {
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                            Text("No labels found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
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
            LazyHGrid(
                rows: [
                    GridItem(.fixed(32), spacing: 8),
                    GridItem(.fixed(32), spacing: 8),
                    GridItem(.fixed(32), spacing: 8)
                ],
                alignment: .top,
                spacing: 8
            ) {
                // Use searchResults when search is active, otherwise use tagEntities
                let tagsToDisplay = isSearchActive ? searchResults : Array(tagEntities)

                ForEach(tagsToDisplay, id: \.objectID) { entity in
                    if let name = entity.name {
                        // When searching, show all results (already filtered by predicate)
                        // When not searching, filter with shouldShowTag()
                        let shouldShow = isSearchActive ? !selectedLabelsSet.contains(name) : shouldShowTag(name)

                        if shouldShow {
                            UnifiedLabelChip(
                                label: name,
                                isSelected: false,
                                isRemovable: false,
                                onTap: {
                                    onToggleLabel(name)
                                }
                            )
                            .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
            }
            .frame(height: 120) // 3 rows * 32px + 2 * 8px spacing
            .padding(.horizontal)
        }
    }

    // MARK: - Computed Properties & Helper Functions

    private var allTagNames: [String] {
        tagEntities.compactMap { $0.name }
    }

    private var filteredTagsCount: Int {
        if isSearchActive {
            return searchResults.count
        } else if searchText.wrappedValue.isEmpty {
            return tagEntities.count
        } else {
            return tagEntities.filter { entity in
                guard let name = entity.name else { return false }
                return name.localizedCaseInsensitiveContains(searchText.wrappedValue)
            }.count
        }
    }

    private var availableUnselectedTagsCount: Int {
        if isSearchActive {
            return searchResults.filter { entity in
                guard let name = entity.name else { return false }
                return !selectedLabelsSet.contains(name)
            }.count
        } else {
            return tagEntities.filter { entity in
                guard let name = entity.name else { return false }
                let matchesSearch = searchText.wrappedValue.isEmpty || name.localizedCaseInsensitiveContains(searchText.wrappedValue)
                let isNotSelected = !selectedLabelsSet.contains(name)
                return matchesSearch && isNotSelected
            }.count
        }
    }

    private func shouldShowTag(_ name: String) -> Bool {
        let matchesSearch = searchText.wrappedValue.isEmpty || name.localizedCaseInsensitiveContains(searchText.wrappedValue)
        let isNotSelected = !selectedLabelsSet.contains(name)
        return matchesSearch && isNotSelected
    }

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            isSearchActive = false
            searchResults = []
            return
        }

        // Search directly in Core Data without fetchLimit
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)

        // Use same sort order as main fetch
        let sortDescriptors: [NSSortDescriptor]
        switch sortOrder {
        case .byCount:
            sortDescriptors = [
                NSSortDescriptor(keyPath: \TagEntity.count, ascending: false),
                NSSortDescriptor(keyPath: \TagEntity.name, ascending: true)
            ]
        case .alphabetically:
            sortDescriptors = [
                NSSortDescriptor(keyPath: \TagEntity.name, ascending: true)
            ]
        }
        fetchRequest.sortDescriptors = sortDescriptors

        // NO fetchLimit - search ALL tags in database
        searchResults = (try? context.fetch(fetchRequest)) ?? []
        isSearchActive = true
    }

    @ViewBuilder
    private var selectedLabels: some View {
        if !selectedLabelsSet.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Selected labels")
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
