//
//  TagEntityMapper.swift
//  readeck
//
//  Created by Ilyas Hallak on 11.08.25.
//

import Foundation
import CoreData

extension BookmarkLabelDto {

    @discardableResult
    func toEntity(context: NSManagedObjectContext) -> TagEntity {
        let entity = TagEntity(context: context)
        entity.name = name
        entity.count = Int32(count)
        return entity
    }
}
