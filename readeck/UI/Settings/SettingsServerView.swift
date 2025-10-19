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

    init(showingLogoutAlert: Bool = false) {
        self.showingLogoutAlert = showingLogoutAlert
    }

    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: viewModel.isSetupMode ? "Server Settings".localized : "Server Connection".localized, icon: "server.rack")
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
                // Server Endpoint
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.isSetupMode {
                        TextField("",
                                  text: $viewModel.endpoint,
                                  prompt: Text("Server Endpoint").foregroundColor(.secondary))
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: viewModel.endpoint) {
                                viewModel.clearMessages()
                            }

                        // Quick Input Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                QuickInputChip(text: "http://", action: {
                                    if !viewModel.endpoint.starts(with: "http") {
                                        viewModel.endpoint = "http://" + viewModel.endpoint
                                    }
                                })
                                QuickInputChip(text: "https://", action: {
                                    if !viewModel.endpoint.starts(with: "http") {
                                        viewModel.endpoint = "https://" + viewModel.endpoint
                                    }
                                })
                                QuickInputChip(text: "192.168.", action: {
                                    if viewModel.endpoint.isEmpty || viewModel.endpoint == "http://" || viewModel.endpoint == "https://" {
                                        if viewModel.endpoint.starts(with: "http") {
                                            viewModel.endpoint += "192.168."
                                        } else {
                                            viewModel.endpoint = "http://192.168."
                                        }
                                    }
                                })
                                QuickInputChip(text: ":8000", action: {
                                    if !viewModel.endpoint.contains(":") || viewModel.endpoint.hasSuffix("://") {
                                        viewModel.endpoint += ":8000"
                                    }
                                })
                            }
                            .padding(.horizontal, 1)
                        }

                        Text("HTTP/HTTPS supported. HTTP only for local networks. Port optional. No trailing slash needed.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        HStack {
                            Image(systemName: "server.rack")
                                .foregroundColor(.accentColor)
                            Text(viewModel.endpoint.isEmpty ? "Not set" : viewModel.endpoint)
                                .foregroundColor(viewModel.endpoint.isEmpty ? .secondary : .primary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                }

                // Username
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.isSetupMode {
                        TextField("",
                                  text: $viewModel.username,
                                  prompt: Text("Username").foregroundColor(.secondary))
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: viewModel.username) {
                                viewModel.clearMessages()
                            }
                    } else {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.accentColor)
                            Text(viewModel.username.isEmpty ? "Not set" : viewModel.username)
                                .foregroundColor(viewModel.username.isEmpty ? .secondary : .primary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                }

                // Password
                if viewModel.isSetupMode {
                    VStack(alignment: .leading, spacing: 8) {
                        SecureField("",
                                    text: $viewModel.password,
                                    prompt: Text("Password").foregroundColor(.secondary))
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: viewModel.password) {
                                viewModel.clearMessages()
                            }
                    }
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
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.caption)
                        Text("Logout")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .foregroundColor(.secondary)
                    .cornerRadius(8)
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

// MARK: - Quick Input Chip Component

struct QuickInputChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .foregroundColor(.secondary)
                .cornerRadius(12)
        }
    }
}
