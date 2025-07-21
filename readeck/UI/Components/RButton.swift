//
//  RButton.swift
//  readeck
//
//  Created by Ilyas Hallak on 21.07.25.
//
//  SPDX-License-Identifier: MIT
//
//  This file is part of the readeck project and is licensed under the MIT License.
//

import SwiftUI

struct RButton<Label: View>: View {
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    let icon: String?
    let label: () -> Label
    
    init(isLoading: Bool = false, isDisabled: Bool = false, icon: String? = nil, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.icon = icon
        self.label = label
    }
    
    var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                if let icon = icon {
                    Image(systemName: icon)
                }
                label()
            }
            .font(.title3.bold())
            .frame(maxHeight: 60)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.bordered)
        .disabled(isLoading || isDisabled)
    }
}

#Preview {
    Group {
        RButton(isLoading: false, isDisabled: false, icon: "star.fill", action: {}) {
            Text("Favorite")
                .foregroundColor(.yellow)
        }
        .padding()
        .preferredColorScheme(.light)
        
        RButton(isLoading: true, isDisabled: false, action: {}) {
            Text("Loading...")
        }
        .padding()
        .preferredColorScheme(.dark)
        
        RButton(isLoading: false, isDisabled: true, icon: nil, action: {}) {
            Text("Disabled")
        }
        .padding()
        .preferredColorScheme(.dark)
        
        RButton(isLoading: false, isDisabled: false, icon: nil, action: {}) {
            Text("No Icon")
        }
        .padding()
        .preferredColorScheme(.light)
    }
}
