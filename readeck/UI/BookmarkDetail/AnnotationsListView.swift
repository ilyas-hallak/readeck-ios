import SwiftUI

struct AnnotationsListView: View {
    let bookmarkId: String
    @State private var viewModel = AnnotationsListViewModel()
    @Environment(\.dismiss) private var dismiss
    var onAnnotationTap: ((String) -> Void)?

    enum ViewState {
        case loading
        case empty
        case loaded([Annotation])
        case error(String)
    }

    private var viewState: ViewState {
        if viewModel.isLoading {
            return .loading
        } else if let error = viewModel.errorMessage, viewModel.showErrorAlert {
            return .error(error)
        } else if viewModel.annotations.isEmpty {
            return .empty
        } else {
            return .loaded(viewModel.annotations)
        }
    }

    var body: some View {
        List {
            switch viewState {
            case .loading:
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }

            case .empty:
                ContentUnavailableView(
                    "No Annotations",
                    systemImage: "pencil.slash",
                    description: Text("This bookmark has no annotations yet.")
                )

            case .loaded(let annotations):
                ForEach(annotations) { annotation in
                    Button(action: {
                        onAnnotationTap?(annotation.id)
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            if !annotation.text.isEmpty {
                                Text(annotation.text)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }

                            Text(formatDate(annotation.created))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

            case .error:
                EmptyView()
            }
        }
        .navigationTitle("Annotations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            await viewModel.loadAnnotations(for: bookmarkId)
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoFormatterNoMillis = ISO8601DateFormatter()
        isoFormatterNoMillis.formatOptions = [.withInternetDateTime]
        var date: Date?
        if let parsedDate = isoFormatter.date(from: dateString) {
            date = parsedDate
        } else if let parsedDate = isoFormatterNoMillis.date(from: dateString) {
            date = parsedDate
        }
        if let date = date {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            displayFormatter.locale = .autoupdatingCurrent
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

#Preview {
    NavigationStack {
        AnnotationsListView(bookmarkId: "123")
    }
}
