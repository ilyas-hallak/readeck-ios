//
//  SettingsServerView.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import SwiftUI

struct SettingsServerView: View {
    @State private var viewModel = SettingsServerViewModel()
    @State private var showingLogoutAlert = false
    
    init(viewModel: SettingsServerViewModel = SettingsServerViewModel(), showingLogoutAlert: Bool = false) {
        self.viewModel = viewModel
        self.showingLogoutAlert = showingLogoutAlert
    }
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: viewModel.isSetupMode ? "Server Settings" : "Server Connection", icon: "server.rack")
                .padding(.bottom, 4)
            
            Text(viewModel.isSetupMode ?
                 "Enter your Readeck server details to get started." :
                 "Your current server connection and login credentials.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            
            // Form
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Server Endpoint")
                        .font(.headline)
                    TextField("https://readeck.example.com", text: $viewModel.endpoint)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .disabled(!viewModel.isSetupMode)
                        .onChange(of: viewModel.endpoint) {
                            if viewModel.isSetupMode {
                                viewModel.clearMessages()
                            }
                        }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Username")
                        .font(.headline)
                    TextField("Your Username", text: $viewModel.username)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .disabled(!viewModel.isSetupMode)
                        .onChange(of: viewModel.username) {
                            if viewModel.isSetupMode {
                                viewModel.clearMessages()
                            }
                        }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.headline)
                    SecureField("Your Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .disabled(!viewModel.isSetupMode)
                        .onChange(of: viewModel.password) {
                            if viewModel.isSetupMode {
                                viewModel.clearMessages()
                            }
                        }
                }
            }
            
            // Connection Status
            if viewModel.isLoggedIn {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Successfully logged in")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            // Messages
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            if let successMessage = viewModel.successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            if viewModel.isSetupMode {
                VStack(spacing: 10) {
                    Button(action: {
                        Task {
                            await viewModel.saveServerSettings()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(viewModel.isLoading ? "Saving..." : (viewModel.isLoggedIn ? "Re-login & Save" : "Login & Save"))
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canLogin ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!viewModel.canLogin || viewModel.isLoading)                    
                }
            } else {
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Logout")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                Task {
                    await viewModel.logout()
                }
            }
        } message: {
            Text("Are you sure you want to log out? This will delete all your login credentials and return you to setup.")
        }
        .task {
            await viewModel.loadServerSettings()
        }
    }
}

#Preview {
    SettingsServerView(viewModel: .init(
        MockUseCaseFactory()
    ))
}
