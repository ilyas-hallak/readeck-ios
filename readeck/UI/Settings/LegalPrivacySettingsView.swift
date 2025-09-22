import SwiftUI

struct LegalPrivacySettingsView: View {
    @State private var showingPrivacyPolicy = false
    @State private var showingLegalNotice = false
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Legal & Privacy".localized, icon: "doc.text")
                .padding(.bottom, 4)
            
            VStack(spacing: 16) {
                // Privacy Policy
                Button(action: {
                    showingPrivacyPolicy = true
                }) {
                    HStack {
                        Text(NSLocalizedString("Privacy Policy", comment: ""))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                
                // Legal Notice
                Button(action: {
                    showingLegalNotice = true
                }) {
                    HStack {
                        Text(NSLocalizedString("Legal Notice", comment: ""))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Support Section
                VStack(spacing: 12) {
                    // Report an Issue
                    Button(action: {
                        if let url = URL(string: "https://github.com/ilyas-hallak/readeck-ios/issues") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text(NSLocalizedString("Report an Issue", comment: ""))
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    
                    // Contact Support
                    Button(action: {
                        if let url = URL(string: "mailto:hi@ilyashallak.de?subject=readeck%20iOS") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text(NSLocalizedString("Contact Support", comment: ""))
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingLegalNotice) {
            LegalNoticeView()
        }
    }
}

#Preview {
    LegalPrivacySettingsView()
        .cardStyle()
        .padding()
}