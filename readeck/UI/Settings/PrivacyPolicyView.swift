import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("Last updated: September 20, 2025")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        sectionView(
                            title: "Data Collection",
                            content: "readeck iOS does not collect, store, or transmit any personal data. The app operates as a client for your personal readeck server and all data remains on your device or your own server infrastructure."
                        )
                        
                        sectionView(
                            title: "Local Storage",
                            content: "The app stores bookmarks locally on your device using CoreData for offline access. Login credentials are securely stored in the iOS Keychain. No data is shared with third parties."
                        )
                        
                        sectionView(
                            title: "Server Communication",
                            content: "The app communicates only with your configured readeck server to synchronize bookmarks. No analytics, tracking, or telemetry data is collected or transmitted."
                        )
                        
                        sectionView(
                            title: "Third-Party Services",
                            content: "This app does not use any third-party analytics, advertising, or tracking services. It does not integrate with social media platforms or other external services."
                        )
                        
                        sectionView(
                            title: "Your Rights",
                            content: "Since no personal data is collected, processed, or stored by us, there is no personal data to access, modify, or delete from our side. All your data is under your control on your device and server."
                        )
                        
                        sectionView(
                            title: "Contact",
                            content: "If you have questions about this privacy policy, please contact us at: hi@ilyashallak.de"
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func sectionView(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PrivacyPolicyView()
}
