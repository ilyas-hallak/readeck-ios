import SwiftUI

struct AppearanceSettingsView: View {
    @State private var selectedCardLayout: CardLayoutStyle = .magazine
    @State private var selectedTheme: Theme = .system
    
    private let loadCardLayoutUseCase: PLoadCardLayoutUseCase
    private let saveCardLayoutUseCase: PSaveCardLayoutUseCase
    private let settingsRepository: PSettingsRepository
    
    init(factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.loadCardLayoutUseCase = factory.makeLoadCardLayoutUseCase()
        self.saveCardLayoutUseCase = factory.makeSaveCardLayoutUseCase()
        self.settingsRepository = SettingsRepository()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Appearance".localized, icon: "paintbrush")
                .padding(.bottom, 4)
            
            // Theme Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(.headline)
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedTheme) {
                    saveThemeSettings()
                }
            }
            
            Divider()
            
            // Card Layout Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Card Layout")
                    .font(.headline)
                
                VStack(spacing: 16) {
                    ForEach(CardLayoutStyle.allCases, id: \.self) { layout in
                        CardLayoutPreview(
                            layout: layout,
                            isSelected: selectedCardLayout == layout
                        ) {
                            selectedCardLayout = layout
                            saveCardLayoutSettings()
                        }
                    }
                }
            }
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        Task {
            // Load both theme and card layout from repository
            if let settings = try? await settingsRepository.loadSettings() {
                await MainActor.run {
                    selectedTheme = settings.theme ?? .system
                }
            }
            selectedCardLayout = await loadCardLayoutUseCase.execute()
        }
    }
    
    private func saveThemeSettings() {
        Task {
            // Load current settings, update theme, and save back
            var settings = (try? await settingsRepository.loadSettings()) ?? Settings()
            settings.theme = selectedTheme
            try? await settingsRepository.saveSettings(settings)
            
            // Notify app about theme change
            await MainActor.run {
                NotificationCenter.default.post(name: .settingsChanged, object: nil)
            }
        }
    }
    
    private func saveCardLayoutSettings() {
        Task {
            await saveCardLayoutUseCase.execute(layout: selectedCardLayout)
            // Notify other parts of the app about the change
            await MainActor.run {
                NotificationCenter.default.post(name: .cardLayoutChanged, object: selectedCardLayout)
            }
        }
    }
}


struct CardLayoutPreview: View {
    let layout: CardLayoutStyle
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Visual Preview
                switch layout {
                case .compact:
                    // Compact: Small image on left, content on right
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.primary.opacity(0.8))
                                .frame(height: 6)
                                .frame(maxWidth: .infinity)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.primary.opacity(0.6))
                                .frame(height: 4)
                                .frame(maxWidth: 60)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.primary.opacity(0.4))
                                .frame(height: 4)
                                .frame(maxWidth: 40)
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: 80, height: 50)
                
                case .magazine:
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.6))
                            .frame(height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.primary.opacity(0.8))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.primary.opacity(0.6))
                                .frame(height: 4)
                                .frame(maxWidth: 40)
                            
                            Text("Fixed 140px")
                                .font(.system(size: 7))
                                .foregroundColor(.secondary)
                                .padding(.top, 1)
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: 80, height: 65)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                case .natural:
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.6))
                            .frame(height: 38)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.primary.opacity(0.8))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.primary.opacity(0.6))
                                .frame(height: 4)
                                .frame(maxWidth: 35)
                            
                            Text("Original ratio")
                                .font(.system(size: 7))
                                .foregroundColor(.secondary)
                                .padding(.top, 1)
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: 80, height: 75) // Höher als Magazine
                    .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(layout.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(layout.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    AppearanceSettingsView()
        .cardStyle()
        .padding()
}
