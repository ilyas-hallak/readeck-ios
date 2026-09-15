//
//  PDFExportProgressOverlay.swift
//  readeck
//
//  Blocking progress indicator for the PDF export, which renders offscreen and can
//  take a moment on a long article with images.
//

import SwiftUI

struct PDFExportProgressOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("Exporting PDF...".localized)
                    .font(.subheadline)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .transition(.opacity)
        // The export cannot be cancelled halfway through, so swallow taps instead of
        // letting them reach the reader underneath.
        .contentShape(Rectangle())
        .onTapGesture {}
    }
}

#Preview {
    Text("Article")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay { PDFExportProgressOverlay() }
}
