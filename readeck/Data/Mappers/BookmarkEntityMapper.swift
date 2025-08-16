import Foundation
import CoreData


// MARK: - DTO -> Entity

extension BookmarkDto {
    func toEntity(context: NSManagedObjectContext) -> BookmarkEntity {
        let entity = BookmarkEntity(context: context)
        entity.title = self.title
        entity.url = self.url
        entity.authors = self.authors.first
        entity.desc = self.description
        entity.created = self.created
        
        entity.siteName = self.siteName
        entity.site = self.site
        entity.authors = self.authors.first // TODO: support multiple authors
        entity.published = self.published
        entity.created = self.created
        entity.update = self.updated
        entity.readingTime = Int16(self.readingTime ?? 0)
        entity.readProgress = Int16(self.readProgress)
        entity.wordCount = Int64(self.wordCount ?? 0)
        entity.isArchived = self.isArchived
        entity.isMarked = self.isMarked
        entity.hasArticle = self.hasArticle
        entity.loaded = self.loaded
        entity.hasDeleted = self.isDeleted
        entity.documentType = self.documentType
        entity.href = self.href
        entity.lang = self.lang
        entity.textDirection = self.textDirection
        entity.type = self.type
        entity.state = Int16(self.state)
        
        // entity.resources = self.resources.toEntity(context: context)
        
        return entity
    }
}

extension BookmarkResourcesDto {
    func toEntity(context: NSManagedObjectContext) -> BookmarkResourcesEntity {
        let entity = BookmarkResourcesEntity(context: context)
        
        entity.article = self.article?.toEntity(context: context)
        entity.icon = self.icon?.toEntity(context: context)
        entity.image = self.image?.toEntity(context: context)
        entity.log = self.log?.toEntity(context: context)
        entity.props = self.props?.toEntity(context: context)
        entity.thumbnail = self.thumbnail?.toEntity(context: context)
        
        return entity
    }
}

extension ImageResourceDto {
    func toEntity(context: NSManagedObjectContext) -> ImageResourceEntity {
        let entity = ImageResourceEntity(context: context)
        entity.src = self.src
        entity.width = Int64(self.width)
        entity.height = Int64(self.height)
        return entity
    }
}

extension ResourceDto {
    func toEntity(context: NSManagedObjectContext) -> ResourceEntity {
        let entity = ResourceEntity(context: context)
        entity.src = self.src
        return entity
    }
}

// ------------------------------------------------

// MARK: - BookmarkEntity to Domain Mapping
extension BookmarkEntity {
    
}

// MARK: - Domain to BookmarkEntity Mapping
extension Bookmark {
    func toEntity(context: NSManagedObjectContext) -> BookmarkEntity {
        let entity = BookmarkEntity(context: context)
        entity.populateFrom(bookmark: self)
        return entity
    }
    
    func updateEntity(_ entity: BookmarkEntity) {
        entity.populateFrom(bookmark: self)
    }
}

extension Resource {
    func toEntity(context: NSManagedObjectContext) -> ResourceEntity {
        let entity = ResourceEntity(context: context)
        entity.populateFrom(resource: self)
        return entity
    }
}

// MARK: - Private Helper Methods
private extension BookmarkEntity {
    func populateFrom(bookmark: Bookmark) {
        self.id = bookmark.id
        self.title = bookmark.title
        self.url = bookmark.url
        self.desc = bookmark.description
        self.siteName = bookmark.siteName
        self.site = bookmark.site
        self.authors = bookmark.authors.first // TODO: support multiple authors
        self.published = bookmark.published
        self.created = bookmark.created
        self.update = bookmark.updated
        self.readingTime = Int16(bookmark.readingTime ?? 0)
        self.readProgress = Int16(bookmark.readProgress)
        self.wordCount = Int64(bookmark.wordCount ?? 0)
        self.isArchived = bookmark.isArchived
        self.isMarked = bookmark.isMarked
        self.hasArticle = bookmark.hasArticle
        self.loaded = bookmark.loaded
        self.hasDeleted = bookmark.isDeleted
        self.documentType = bookmark.documentType
        self.href = bookmark.href
        self.lang = bookmark.lang
        self.textDirection = bookmark.textDirection
        self.type = bookmark.type
        self.state = Int16(bookmark.state)
    }
}

// MARK: - BookmarkState Mapping
private extension BookmarkState {
    static func fromRawValue(_ value: Int) -> BookmarkState {
        switch value {
        case 0: return .unread
        case 1: return .favorite
        case 2: return .archived
        default: return .unread
        }
    }
}

private extension BookmarkResourcesEntity {
    func populateFrom(bookmarkResources: BookmarkResources) {
        
    }
}

private extension ImageResourceEntity {
    func populateFrom(imageResource: ImageResource) {
        self.src = imageResource.src
        self.height = Int64(imageResource.height)
        self.width = Int64(imageResource.width)
    }
}

private extension ResourceEntity {
    func populateFrom(resource: Resource) {
        self.src = resource.src
    }
}

// MARK: - Date Conversion Helpers
private extension String {
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: self) ?? 
               ISO8601DateFormatter().date(from: self)
    }
}

private extension Date {
    func toISOString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}

// MARK: - Array Mapping Extensions
extension Array where Element == BookmarkEntity {
    func toDomain() -> [Bookmark] {
        return [] // self.map { $0.toDomain() }
    }
}

extension Array where Element == Bookmark {
    func toEntities(context: NSManagedObjectContext) -> [BookmarkEntity] {
        return self.map { $0.toEntity(context: context) }
    }
}
/*
extension BookmarkEntity {
    func toDomain() -> Bookmark {
        return Bookmark(id: id ?? "", title: title ?? "", url: url!, href: href ?? "", description: description, authors: [authors ?? ""], created: created ?? "", published: published, updated: update!, siteName: siteName ?? "", site: site!, readingTime: Int(readingTime), wordCount: Int(wordCount), hasArticle: hasArticle, isArchived: isArchived, isDeleted: isDeleted, isMarked: isMarked, labels: [], lang: lang, loaded: loaded, readProgress: Int(readProgress), documentType: documentType ?? "", state: Int(state), textDirection: textDirection ?? "", type: type ?? "", resources: resources.toDomain())
        )
    }
}

extension BookmarkResourcesEntity {
    func toDomain() -> BookmarkResources {
        return BookmarkResources(article: ar, icon: <#T##ImageResource?#>, image: <#T##ImageResource?#>, log: <#T##Resource?#>, props: <#T##Resource?#>, thumbnail: <#T##ImageResource?#>
    }
}

extension ImageResourceEntity {
    
}
*/
