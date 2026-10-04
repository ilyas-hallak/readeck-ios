import SwiftUI

struct ShareByEmailView: View {
    @State private var viewModel: ShareByEmailViewModel
    @State private var showingSentConfirmation = false
    @Environment(\.dismiss) private var dismiss

    init(bookmarkId: String) {
        self._viewModel = State(initialValue: ShareByEmailViewModel(bookmarkId: bookmarkId))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email address".localized, text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Format".localized) {
                    Picker("Format".localized, selection: $viewModel.format) {
                        ForEach(EmailShareFormat.allCases) { format in
                            Text(format.localizedTitle).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Send by Email".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Cancel".localized, systemImage: "xmark")
                            .labelStyle(.iconOnly)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    sendButton
                }
            }
            .alert("Email Sent".localized, isPresented: $showingSentConfirmation) {
                Button("OK".localized) {
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private var sendButton: some View {
        if viewModel.isSending {
            ProgressView()
        } else {
            Button("Send".localized) {
                Task {
                    showingSentConfirmation = await viewModel.send()
                }
            }
            .disabled(!viewModel.canSend)
        }
    }
}
