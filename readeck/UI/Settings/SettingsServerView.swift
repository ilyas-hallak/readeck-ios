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

    var body: some View {
        Section {
            SettingsRowValue(
                icon: "server.rack",
                title: "Server",
                value: viewModel.endpoint.isEmpty ? "Not set" : viewModel.endpoint
            )

            SettingsRowValue(
                icon: "person.circle.fill",
                title: "Username",
                value: viewModel.username.isEmpty ? "Not set" : viewModel.username
            )

            SettingsRowButton(
                icon: "rectangle.portrait.and.arrow.right",
                iconColor: .red,
                title: "Logout",
                subtitle: nil,
                destructive: true
            ) {
                showingLogoutAlert = true
            }
        } header: {
            Text("Server Connection")
        } footer: {
            Text("Your current server connection and login credentials.")
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
    List {
        SettingsServerView()
    }
    .listStyle(.insetGrouped)
}
