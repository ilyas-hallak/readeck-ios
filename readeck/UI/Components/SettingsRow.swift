//
//  SettingsRow.swift
//  readeck
//
//  Created by Ilyas Hallak on 31.10.25.
//

import SwiftUI

// MARK: - Settings Row with Navigation Link
struct SettingsRowNavigationLink<Destination: View>: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let subtitle: String?
    let destination: Destination

    init(
        icon: String? = nil,
        iconColor: Color = .accentColor,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder destination: () -> Destination
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.destination = destination()
    }

    var body: some View {
        NavigationLink(destination: destination) {
            SettingsRowLabel(
                icon: icon,
                iconColor: iconColor,
                title: title,
                subtitle: subtitle
            )
        }
    }
}

// MARK: - Settings Row with Toggle
struct SettingsRowToggle: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    init(
        icon: String? = nil,
        iconColor: Color = .accentColor,
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        HStack {
            SettingsRowLabel(
                icon: icon,
                iconColor: iconColor,
                title: title,
                subtitle: subtitle
            )
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

// MARK: - Settings Row with Value Display
struct SettingsRowValue: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let value: String
    let valueColor: Color

    init(
        icon: String? = nil,
        iconColor: Color = .accentColor,
        title: String,
        value: String,
        valueColor: Color = .secondary
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.valueColor = valueColor
    }

    var body: some View {
        HStack {
            SettingsRowLabel(
                icon: icon,
                iconColor: iconColor,
                title: title,
                subtitle: nil
            )
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Settings Row Button (for actions)
struct SettingsRowButton: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let subtitle: String?
    let destructive: Bool
    let action: () -> Void

    init(
        icon: String? = nil,
        iconColor: Color = .accentColor,
        title: String,
        subtitle: String? = nil,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.destructive = destructive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            SettingsRowLabel(
                icon: icon,
                iconColor: destructive ? .red : iconColor,
                title: title,
                subtitle: subtitle,
                titleColor: destructive ? .red : .primary
            )
        }
    }
}

// MARK: - Settings Row with Picker
struct SettingsRowPicker<T: Hashable>: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let selection: Binding<T>
    let options: [(value: T, label: String)]

    init(
        icon: String? = nil,
        iconColor: Color = .accentColor,
        title: String,
        selection: Binding<T>,
        options: [(value: T, label: String)]
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.selection = selection
        self.options = options
    }

    var body: some View {
        HStack {
            SettingsRowLabel(
                icon: icon,
                iconColor: iconColor,
                title: title,
                subtitle: nil
            )
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
    }
}

// MARK: - Settings Row Label (internal component)
struct SettingsRowLabel: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let subtitle: String?
    let titleColor: Color

    init(
        icon: String?,
        iconColor: Color,
        title: String,
        subtitle: String?,
        titleColor: Color = .primary
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.titleColor = titleColor
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(titleColor)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Navigation Link") {
    List {
        SettingsRowNavigationLink(
            icon: "paintbrush",
            title: "App Icon",
            subtitle: nil
        ) {
            Text("Detail View")
        }
    }
    .listStyle(.insetGrouped)
}

#Preview("Toggle") {
    List {
        SettingsRowToggle(
            icon: "speaker.wave.2",
            title: "Read Aloud Feature",
            subtitle: "Text-to-Speech functionality",
            isOn: .constant(true)
        )
    }
    .listStyle(.insetGrouped)
}

#Preview("Value Display") {
    List {
        SettingsRowValue(
            icon: "paintbrush.fill",
            iconColor: .purple,
            title: "Tint Color",
            value: "Purple"
        )
    }
    .listStyle(.insetGrouped)
}

#Preview("Button") {
    List {
        SettingsRowButton(
            icon: "trash",
            iconColor: .red,
            title: "Clear Cache",
            subtitle: "Remove all cached images",
            destructive: true
        ) {
            print("Clear cache tapped")
        }
    }
    .listStyle(.insetGrouped)
}

#Preview("Picker") {
    List {
        SettingsRowPicker(
            icon: "textformat",
            title: "Font Family",
            selection: .constant("System"),
            options: [
                ("System", "System"),
                ("Serif", "Serif"),
                ("Monospace", "Monospace")
            ]
        )
    }
    .listStyle(.insetGrouped)
}
