import SwiftUI

struct ArticleSummaryCardView: View {
    @Bindable var viewModel: ArticleSummaryViewModel
    var backgroundColor: Color = Color(.secondarySystemBackground)
    var textColor: Color = .primary
    @State private var summaryTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header — always tappable
            headerButton

            // Expandable content
            if viewModel.isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Header

    private var headerButton: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(.accentColor)
            Text(viewModel.hasGenerated ? "Summary".localized : "Summarize".localized)
                .font(.subheadline.weight(.medium))
                .foregroundColor(textColor)
            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if viewModel.hasGenerated {
                Image(systemName: viewModel.isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(textColor.opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            if viewModel.hasGenerated {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.isExpanded.toggle()
                }
            } else {
                Task {
                    await viewModel.summarize()
                }
            }
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.horizontal, 14)

            if viewModel.isLoading && viewModel.summaryMarkdown.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating summary...".localized)
                        .font(.caption)
                        .foregroundColor(textColor.opacity(0.6))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            } else if let error = viewModel.error {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(textColor.opacity(0.6))
                    Button("Retry".localized) {
                        Task { await viewModel.summarize() }
                    }
                    .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            } else if !viewModel.summaryMarkdown.isEmpty {
                MarkdownContentView(content: viewModel.summaryMarkdown, textColor: textColor)
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)
            }

            // Language picker
            if viewModel.hasGenerated && !viewModel.availableLanguages.isEmpty {
                HStack {
                    Spacer()
                    Picker("", selection: Binding(
                        get: { viewModel.selectedLanguage },
                        set: { newValue in
                            viewModel.selectedLanguage = newValue
                            summaryTask?.cancel()
                            summaryTask = Task {
                                await viewModel.summarize()
                            }
                        }
                    )) {
                        ForEach(viewModel.availableLanguages, id: \.code) { language in
                            Text(language.displayName).tag(language.code)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.caption)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
            }
        }
    }
}
