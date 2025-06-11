import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Anmeldedaten"), footer: SectionFooter()) {
                    TextField("Benutzername", text: $viewModel.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    SecureField("Passwort", text: $viewModel.password)
                    
                    TextField("Endpoint", text: $viewModel.endpoint)                        
                        .keyboardType(.URL)
                    
                    Button {
                        Task {
                            await viewModel.login()
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Speichern")
                        }
                    }
                    .disabled(viewModel.isLoginDisabled)
                }
                
                
            }
            .navigationTitle("Einstellungen")
        }
    }
    
    @ViewBuilder
    private func SectionFooter() -> some View {
        switch viewModel.state {
        case .error:
            Text("Anmeldung fehlgeschlagen. Bitte überprüfen Sie Ihre Eingaben.")
                .foregroundColor(.red)
        case .success:
            Text("Anmeldung erfolgreich!")
                .foregroundColor(.green)
        case .default:
            Text("")                
        }
    }
}

#Preview {
    SettingsView()
}
