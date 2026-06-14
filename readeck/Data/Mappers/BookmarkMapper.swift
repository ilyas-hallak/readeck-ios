import Foundation

extension BookmarksPageDto {
    func toDomain() -> BookmarksPage {
        BookmarksPage(
            bookmarks: bookmarks.map { $0.toDomain() },
            currentPage: currentPage,
            totalCount: totalCount,
            totalPages: totalPages,
            links: links
        )
    }
}

// MARK: - BookmarkDto to Domain Mapping
extension BookmarkDto {
    func toDomain() -> Bookmark {
        Bookmark(
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
        BookmarkResources(
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
        Resource(src: src)
    }
}

extension ImageResourceDto {
    func toDomain() -> ImageResource {
        ImageResource(src: src, height: height, width: width)
    }
}

extension BookmarkLabelDto {
    func toDomain() -> BookmarkLabel {
        BookmarkLabel(name: self.name, count: self.count, href: self.href)
    }
}
