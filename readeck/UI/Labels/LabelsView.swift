import SwiftUI

struct LabelsView: View {
    @State var viewModel = LabelsViewModel()
    @Binding var selectedTag: BookmarkLabel?
    
    init(viewModel: LabelsViewModel = LabelsViewModel(), selectedTag: Binding<BookmarkLabel?>) {
        self.viewModel = viewModel
        self._selectedTag = selectedTag
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                List {
                    ForEach(viewModel.labels, id: \.href) { label in
                        if UIDevice.isPhone {
                            NavigationLink {
                                BookmarksView(state: .all, type: [], selectedBookmark: .constant(nil), tag: label.name)
                                    .navigationTitle("\(label.name) (\(label.count))")
                            } label: {
                                ButtonLabel(label)
                            }
                        } else {
                            Button {
                                selectedTag = nil
                                DispatchQueue.main.async {
                                    selectedTag = label
                                }
                            } label: {
                                ButtonLabel(label)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadLabels()
            }
        }
    }
    
    @ViewBuilder
    private func ButtonLabel(_ label: BookmarkLabel) -> some View {
        HStack {
            Text(label.name)
            Spacer()
            Text("\(label.count)")
                .foregroundColor(.secondary)
        }
    }
}
