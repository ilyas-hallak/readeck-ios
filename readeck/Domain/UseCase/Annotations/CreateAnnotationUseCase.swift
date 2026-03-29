//
//  CreateAnnotationUseCase.swift
//  readeck
//
//  Created by Ilyas Hallak on 30.11.25.
//

import Foundation

protocol PCreateAnnotationUseCase {
    func execute(
        bookmarkId: String,
        color: String,
        startOffset: Int,
        endOffset: Int,
        startSelector: String,
        endSelector: String
    ) async throws -> Annotation
}

final class CreateAnnotationUseCase: PCreateAnnotationUseCase {
    private let repository: PAnnotationsRepository

    init(repository: PAnnotationsRepository) {
        self.repository = repository
    }

    func execute(
        bookmarkId: String,
        color: String,
        startOffset: Int,
        endOffset: Int,
        startSelector: String,
        endSelector: String
    ) async throws -> Annotation {
        try await repository.createAnnotation(
            bookmarkId: bookmarkId,
            color: color,
            startOffset: startOffset,
            endOffset: endOffset,
            startSelector: startSelector,
            endSelector: endSelector
        )
    }
}
