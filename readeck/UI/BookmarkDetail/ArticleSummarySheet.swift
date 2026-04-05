import SwiftUI

struct ArticleSummarySheet: View {
    @State private var viewModel: ArticleSummaryViewModel
    @State private var summaryTask: Task<Void, Never>?

    init(articleContent: String, summarizeUseCase: PSummarizeArticleUseCase) {
        _viewModel = State(initialValue: ArticleSummaryViewModel(
            articleContent: articleContent,
            summarizeUseCase: summarizeUseCase
        ))
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Language picker
                if !viewModel.availableLanguages.isEmpty {
                    Picker("Language".localized, selection: $viewModel.selectedLanguage) {
                        ForEach(viewModel.availableLanguages, id: \.code) { language in
                            Text(language.displayName).tag(language.code)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                }

                // Content area
                if viewModel.isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Generating summary...".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else if let error = viewModel.error {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry".localized) {
                            Task {
                                await viewModel.summarize()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else if !viewModel.summary.isEmpty {
                    ScrollView {
                        Text(viewModel.summary)
                            .font(.body)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Summary".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.summarize()
        }
        .onChange(of: viewModel.selectedLanguage) { _, _ in
            summaryTask?.cancel()
            summaryTask = Task {
                await viewModel.summarize()
            }
        }
    }
}
