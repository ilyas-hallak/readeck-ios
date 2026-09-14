//
//  ActivityView.swift
//  readeck
//
//  SwiftUI wrapper around `UIActivityViewController` for the cases where the share
//  content only exists after some asynchronous work and `ShareLink` cannot be used.
//

import SwiftUI
import UIKit

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
