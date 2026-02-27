//
//  OnboardingServerView.swift
//  readeck
//
//  Created by Ilyas Hallak on 31.10.25.
//

import SwiftUI

struct OnboardingServerView: View {
    @State private var viewModel = SettingsServerViewModel()
    @State private var showLoginFields = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    onboardingContent
                }
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .center)
                .padding(.vertical, 20)
                .padding(.horizontal, isWideLayout ? 24 : 0)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(
                Group {
                    if isWideLayout {
                        Color(.systemGroupedBackground).ignoresSafeArea()
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .task {
            await viewModel.loadServerSettings()
        }
    }

    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }

    @ViewBuilder
    private var onboardingContent: some View {
        if isWideLayout {
            classicLoginForm
                .frame(maxWidth: 620)
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
        } else {
            classicLoginForm
        }
    }

    private var buttonEnabled: Bool {
        if showLoginFields {
            // Phase 2: Need endpoint, username, and password
            return !viewModel.endpoint.isEmpty && !viewModel.username.isEmpty && !viewModel.password.isEmpty
        } else {
            // Phase 1: Only need endpoint
            return !viewModel.endpoint.isEmpty
        }
    }

    private var classicLoginForm: some View {
        VStack(spacing: 20) {
            // Readeck Logo with green background
            ZStack {
                Circle()
                    .fill(Color("green"))
                    .frame(width: 80, height: 80)

                Image("readeck")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
            }
            .padding(.top, 20)
            .padding(.bottom, 8)

            Text(showLoginFields ? "Enter your credentials" : "Enter your Readeck server")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 4)

            Text(showLoginFields ? "Please provide your username and password." : "Enter your server endpoint to get started.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            // Form
            VStack(spacing: 16) {
                // Server Endpoint
                VStack(alignment: .leading, spacing: 8) {
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
                }

                // Username & Password - only show when showLoginFields is true
                if showLoginFields {
                    // Username
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("",
                                  text: $viewModel.username,
                                  prompt: Text("Username").foregroundColor(.secondary))
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: viewModel.username) {
                                viewModel.clearMessages()
                            }
                    }

                    // Password
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

            VStack(spacing: 10) {
                Button(action: {
                    Task {
                        if !showLoginFields {
                            // Phase 1: Check server for OAuth support
                            await viewModel.checkServerOAuthSupport()
                            if viewModel.serverSupportsOAuth {
                                // Try OAuth login
                                await viewModel.loginWithOAuth()
                                // If OAuth fails, error message is shown, user can fallback to classic
                                if viewModel.errorMessage != nil {
                                    showLoginFields = true
                                }
                            } else {
                                // No OAuth → show login fields for classic auth
                                showLoginFields = true
                            }
                        } else {
                            // Phase 2: Classic login
                            await viewModel.saveServerSettings()
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(viewModel.isLoading ? (showLoginFields ? "Logging in..." : "Checking...") : (showLoginFields ? "Login & Save" : "Continue"))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(buttonEnabled ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!buttonEnabled || viewModel.isLoading)
            }
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

#Preview {
    OnboardingServerView()
        .padding()
}
