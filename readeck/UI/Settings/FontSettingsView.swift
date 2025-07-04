//
//  FontSettingsView.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import SwiftUI

struct FontSettingsView: View {
    @State private var viewModel = FontSettingsViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "textformat")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("Schrift")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            // Font Family Picker
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text("Schriftart")
                    .font(.headline)
                Picker("Schriftart", selection: $viewModel.selectedFontFamily) {
                    ForEach(FontFamily.allCases, id: \.self) { family in
                        Text(family.displayName).tag(family)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: viewModel.selectedFontFamily) {
                    Task {
                        await viewModel.saveFontSettings()
                    }
                }
            }
            
            VStack(spacing: 16) {
                
                // Font Size Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Schriftgröße")
                        .font(.headline)
                    Picker("Schriftgröße", selection: $viewModel.selectedFontSize) {
                        ForEach(FontSize.allCases, id: \.self) { size in
                            Text(size.displayName).tag(size)
                        }
                    }                                
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: viewModel.selectedFontSize) {
                        Task {
                            await viewModel.saveFontSettings()
                        }
                    }
                }
                
                // Font Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vorschau")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("readeck Bookmark Title")
                            .font(viewModel.previewTitleFont)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Text("This is how your bookmark descriptions and article text will appear in the app. The quick brown fox jumps over the lazy dog.")
                            .font(viewModel.previewBodyFont)
                            .lineLimit(3)
                        
                        Text("12 min • Today • example.com")
                            .font(viewModel.previewCaptionFont)
                            .foregroundColor(.secondary)
                    }
                    .padding(4)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .task {
            await viewModel.loadFontSettings()
        }
    }
}

#Preview {
    FontSettingsView()
} 
