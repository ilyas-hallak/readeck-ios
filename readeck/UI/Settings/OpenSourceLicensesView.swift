//
//  OpenSourceLicensesView.swift
//  readeck
//
//  Created by Ilyas Hallak on 05.12.25.
//

import SwiftUI

struct OpenSourceLicensesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("This app uses the following open-source fonts under the SIL Open Font License 1.1.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Open Source Fonts")
                }

                Section {
                    FontLicenseRow(
                        name: "Literata",
                        author: "TypeTogether for Google",
                        license: "SIL OFL 1.1"
                    )

                    FontLicenseRow(
                        name: "Merriweather",
                        author: "Sorkin Type",
                        license: "SIL OFL 1.1"
                    )

                    FontLicenseRow(
                        name: "Source Serif",
                        author: "Adobe (Frank Grießhammer)",
                        license: "SIL OFL 1.1"
                    )

                    FontLicenseRow(
                        name: "Lato",
                        author: "Łukasz Dziedzic",
                        license: "SIL OFL 1.1"
                    )

                    FontLicenseRow(
                        name: "Montserrat",
                        author: "Julieta Ulanovsky",
                        license: "SIL OFL 1.1"
                    )

                    FontLicenseRow(
                        name: "Source Sans",
                        author: "Adobe (Paul D. Hunt)",
                        license: "SIL OFL 1.1"
                    )
                } header: {
                    Text("Font Licenses")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SIL Open Font License 1.1")
                            .font(.headline)

                        Text("The SIL Open Font License allows the fonts to be used, studied, modified and redistributed freely as long as they are not sold by themselves.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button(action: {
                            if let url = URL(string: "https://scripts.sil.org/OFL") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Text("View Full License")
                                    .font(.caption)
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("License Information")
                }

                Section {
                    Text("Apple System Fonts (SF Pro, New York, Avenir Next, SF Mono) are proprietary to Apple Inc. and are free to use within iOS applications.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Apple Fonts")
                }
            }
            .navigationTitle("Open Source Licenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FontLicenseRow: View {
    let name: String
    let author: String
    let license: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.headline)
            Text(author)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(license)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    OpenSourceLicensesView()
}
