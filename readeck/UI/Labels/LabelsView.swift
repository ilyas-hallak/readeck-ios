import SwiftUI

struct LabelsView: View {
    @State var viewModel = LabelsViewModel()
    @State private var selectedTag: String? = nil
    @State private var selectedBookmark: Bookmark? = nil
    
    var body: some View {
        VStack(alignment: .leading) {
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                Text("Fehler: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                List {
                    ForEach(viewModel.labels, id: \.href) { label in
                        
                        NavigationLink {
                            BookmarksView(state: .all, type: [], selectedBookmark: .constant(nil), tag: label.name)
                                .navigationTitle("\(label.name) (\(label.count))")
                        } label: {
                            HStack {
                                Text(label.name)
                                Spacer()
                                Text("\(label.count)")
                                    .foregroundColor(.secondary)
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
} 
