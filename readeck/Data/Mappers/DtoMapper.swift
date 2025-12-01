//
//  DtoMapper.swift
//  readeck
//
//  Created by Ilyas Hallak on 30.11.25.
//

extension AnnotationDto {
    func toDomain() -> Annotation {
        Annotation(id: id, text: text, created: created, startOffset: startOffset, endOffset: endOffset, startSelector: startSelector, endSelector: endSelector)
    }
}
