import SwiftUI

struct ShareBookmarkView: View {
    @ObservedObject var viewModel: ShareBookmarkViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo
            Image("readeck")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
                .padding(.top, 24)
                .opacity(0.9)
            // URL
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
            // Titel
            TextField("Enter an optional title...", text: $viewModel.title)
                .font(.system(size: 17, weight: .medium))
                .padding(.horizontal, 10)
                .foregroundColor(.primary)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.accentColor.opacity(viewModel.title.isEmpty ? 0.12 : 0.7), lineWidth: viewModel.title.isEmpty ? 1 : 2)
                )
                .padding(.top, 20)
                .padding(.horizontal, 16)
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Label Grid
            if !viewModel.labels.isEmpty {
                LabelGridView(labels: viewModel.labels, selected: $viewModel.selectedLabels)
                    .padding(.top, 32)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 100)
            }
            // Status
            if let status = viewModel.statusMessage {
                Text(status.emoji + " " + status.text)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(status.isError ? .red : .green)
                    .padding(.top, 32)
                    .padding(.horizontal, 16)
            }
            Spacer()
            // Save Button
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
            .padding(.bottom, 32)
            .disabled(viewModel.isSaving)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear { viewModel.onAppear() }
    }
}

struct LabelGridView: View {
    let labels: [BookmarkLabelDto]
    @Binding var selected: Set<String>
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(labels.prefix(15), id: \ .name) { label in
                Button(action: {
                    if selected.contains(label.name) {
                        selected.remove(label.name)
                    } else {
                        selected.insert(label.name)
                    }
                }) {
                    Text(label.name)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selected.contains(label.name) ? Color.accentColor.opacity(0.2) : Color(.secondarySystemGroupedBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selected.contains(label.name) ? Color.accentColor : Color.clear, lineWidth: 1)
                        )
                }
            }
        }
    }
} 
