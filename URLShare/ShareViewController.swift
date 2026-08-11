//
//  ShareViewController.swift
//  URLShare
//
//  Created by Ilyas Hallak on 11.06.25.
//

import UIKit
import Social
import UniformTypeIdentifiers
import SwiftUI

final class ShareViewController: UIViewController {
    private var hostingController: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        let viewModel = ShareBookmarkViewModel(extensionContext: extensionContext)

        // Extract URL, title, and HTML from JavaScript preprocessing results
        extractJSPreprocessingResults(into: viewModel)

        let swiftUIView = ShareBookmarkView(viewModel: viewModel)
            .environment(\.managedObjectContext, CoreDataManager.shared.context)
        let hostingController = UIHostingController(rootView: AnyView(swiftUIView))
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hostingController.didMove(toParent: self)
        self.hostingController = hostingController

        // Entry point into the responder chain so the view model can open the host app.
        viewModel.hostResponder = hostingController.view

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dismissKeyboard),
            name: .dismissKeyboard,
            object: nil
        )
    }

    private func extractJSPreprocessingResults(into viewModel: ShareBookmarkViewModel) {
        guard let extensionContext else { return }

        for item in extensionContext.inputItems {
            guard let inputItem = item as? NSExtensionItem else { continue }
            for attachment in inputItem.attachments ?? [] {
                if attachment.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) { result, _ in
                        guard let dictionary = result as? NSDictionary,
                              let jsResults = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else {
                            return
                        }
                        DispatchQueue.main.async {
                            if let url = jsResults["url"] as? String {
                                viewModel.url = url
                            }
                            if let title = jsResults["title"] as? String, !title.isEmpty {
                                viewModel.title = title
                            }
                            viewModel.pageHTML = jsResults["html"] as? String
                        }
                    }
                    return
                }
            }
        }
    }

    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
