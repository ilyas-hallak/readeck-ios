import Foundation

// MARK: - BookmarkDto to Domain Mapping
extension BookmarkDto {
    func toDomain() -> Bookmark {
        return Bookmark(
            id: id,
            title: title,
            url: url,
            href: href,
            description: description,
            authors: authors,
            created: created,
            published: published,
            updated: updated,
            siteName: siteName,
            site: site,
            readingTime: readingTime,
            wordCount: wordCount,
            hasArticle: hasArticle,
            isArchived: isArchived,
            isDeleted: isDeleted,
            isMarked: isMarked,
            labels: labels,
            lang: lang,
            loaded: loaded,
            readProgress: readProgress,
            documentType: documentType,
            state: state,
            textDirection: textDirection,
            type: type,
            resources: resources.toDomain()
        )
    }
}

// MARK: - Resources Mapping
extension BookmarkResourcesDto {
    func toDomain() -> BookmarkResources {
        return BookmarkResources(
            article: article?.toDomain(),
            icon: icon?.toDomain(),
            image: image?.toDomain(),
            log: log?.toDomain(),
            props: props?.toDomain(),
            thumbnail: thumbnail?.toDomain()
        )
    }
}

extension ResourceDto {
    func toDomain() -> Resource {
        return Resource(src: src)
    }
}

extension ImageResourceDto {
    func toDomain() -> ImageResource {
        return ImageResource(src: src, height: height, width: width)
    }
}