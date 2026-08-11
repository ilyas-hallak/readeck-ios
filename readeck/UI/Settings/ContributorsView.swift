//
//  ContributorsView.swift
//  readeck
//
//  A small thank-you / credits screen ("Hall of Fame") listing the Readeck
//  project founder, this client's maintainer, and everyone who has contributed
//  to the app across both remotes (GitHub + Codeberg).
//
//  The list is a curated static array (single source of truth): both remotes
//  have separate histories with duplicate/no-reply identities that need manual
//  dedup, and the git history isn't available in the app bundle at runtime.
//
//  Avatars are loaded via Kingfisher from each person's platform
//  (github.com/<login>.png or codeberg.org/<login>.png), cached after first
//  load so the screen keeps working offline; a round person placeholder is
//  shown while loading or when offline without a cached avatar.
//

import SwiftUI
import Kingfisher

struct Contributor: Identifiable {
    let name: String
    let handle: String
    let profileURL: URL?
    let avatarURL: URL?
    /// Optional role line (e.g. "Creator of Readeck").
    let note: String?

    var id: String { handle }

    static func github(_ login: String, name: String, note: String? = nil) -> Contributor {
        Contributor(
            name: name,
            handle: "@\(login)",
            profileURL: URL(string: "https://github.com/\(login)"),
            avatarURL: URL(string: "https://github.com/\(login).png?size=200"),
            note: note
        )
    }

    static func codeberg(_ login: String, name: String, note: String? = nil) -> Contributor {
        Contributor(
            name: name,
            handle: "@\(login)",
            profileURL: URL(string: "https://codeberg.org/\(login)"),
            avatarURL: URL(string: "https://codeberg.org/\(login).png"),
            note: note
        )
    }
}

enum Contributors {
    /// Creator of the upstream Readeck project this client connects to.
    static let founder = Contributor.codeberg("olivier", name: "Olivier Meunier", note: "Creator of Readeck")

    static let maintainer = Contributor.github("ilyas-hallak", name: "Ilyas Hallak")

    // Alphabetical by name. Extend this as new contributions land.
    static let others: [Contributor] = [
        .github("bakerboy448", name: "bakerboy448"),
        .github("benrhughes", name: "Ben Hughes"),
        .github("christian-putzke", name: "Christian Putzke"),
        .github("ishansharma", name: "Ishan Sharma"),
        .github("grabowskil", name: "Lennart Grabowski"),
        .github("sibson", name: "Marc Sibson"),
        .github("astratto", name: "Stefano Tortarolo")
    ]
}

struct ContributorsView: View {
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 20)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Text("Thanks to everyone who has contributed to the app.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                    VStack(spacing: 12) {
                        sectionTitle("Maintainer")
                        ContributorCell(contributor: Contributors.maintainer, avatarSize: 96)
                    }

                    VStack(spacing: 12) {
                        sectionTitle("The Readeck Project")
                        ContributorCell(contributor: Contributors.founder, avatarSize: 72)
                    }

                    VStack(spacing: 16) {
                        sectionTitle("Contributors")
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(Contributors.others) { contributor in
                                ContributorCell(contributor: contributor, avatarSize: 72)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationTitle("Hall of Fame")
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

    @ViewBuilder
    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.footnote.weight(.semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ContributorCell: View {
    let contributor: Contributor
    let avatarSize: CGFloat

    var body: some View {
        Button {
            if let url = contributor.profileURL {
                UIApplication.shared.open(url)
            }
        } label: {
            VStack(spacing: 8) {
                avatar
                VStack(spacing: 2) {
                    Text(contributor.name)
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(contributor.handle)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                    if let note = contributor.note {
                        Text(LocalizedStringKey(note))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var avatar: some View {
        KFImage(contributor.avatarURL)
            .placeholder { placeholder }
            .fade(duration: 0.2)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: avatarSize, height: avatarSize)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
    }

    private var placeholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: avatarSize, height: avatarSize)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: avatarSize * 0.4))
                    .foregroundColor(.gray)
            )
    }
}

#Preview {
    ContributorsView()
}
