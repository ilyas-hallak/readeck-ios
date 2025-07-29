//
//  UnifiedLabelChip.swift
//  readeck
//
//  Created by Ilyas Hallak on 21.07.25.
//
//  SPDX-License-Identifier: MIT
//
//  This file is part of the readeck project and is licensed under the MIT License.
//

import SwiftUI

struct UnifiedLabelChip: View {
    let label: String
    let isSelected: Bool
    let isRemovable: Bool
    let onTap: () -> Void
    let onRemove: (() -> Void)?
    
    init(label: String, isSelected: Bool = false, isRemovable: Bool = false, onTap: @escaping () -> Void, onRemove: (() -> Void)? = nil) {
        self.label = label
        self.isSelected = isSelected
        self.isRemovable = isRemovable
        self.onTap = onTap
        self.onRemove = onRemove
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if isRemovable, let onRemove = onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(minHeight: 32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 16) {
        UnifiedLabelChip(
            label: "Sample Label",
            isSelected: false,
            isRemovable: false,
            onTap: {}
        )
        
        UnifiedLabelChip(
            label: "Selected Label",
            isSelected: true,
            isRemovable: false,
            onTap: {}
        )
        
        UnifiedLabelChip(
            label: "Removable Label",
            isSelected: false,
            isRemovable: true,
            onTap: {},
            onRemove: {}
        )
        
        UnifiedLabelChip(
            label: "Selected & Removable",
            isSelected: true,
            isRemovable: true,
            onTap: {},
            onRemove: {}
        )
    }
    .padding()
} 