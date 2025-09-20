import SwiftUI

struct LegalNoticeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Legal Notice")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        sectionView(
                            title: "App Publisher",
                            content: """
                            Ilyas Hallak
                            [Street Address]
                            [City, Postal Code]
                            [Country]
                            
                            Email: ilhallak@gmail.com
                            """
                        )
                        
                        sectionView(
                            title: "Content Responsibility",
                            content: "The publisher is responsible for the content of this application in accordance with applicable laws."
                        )
                        
                        sectionView(
                            title: "App Information",
                            content: """
                            readeck iOS - Bookmark Management Client
                            Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                            Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                            
                            This app is an open source client for readeck bookmark management.
                            """
                        )
                        
                        sectionView(
                            title: "License",
                            content: "This software is released under the MIT License. The source code is available at the official repository."
                        )
                        
                        sectionView(
                            title: "Disclaimer",
                            content: "The app is provided \"as is\" without warranty of any kind. The publisher assumes no liability for damages arising from the use of this application."
                        )
                        
                        // TODO: Add business registration details if needed
                        // sectionView(
                        //     title: "Business Registration",
                        //     content: """
                        //     [Business Registration Number]
                        //     [Tax ID / VAT Number]
                        //     [Responsible Authority]
                        //     """
                        // )
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
    LegalNoticeView()
}