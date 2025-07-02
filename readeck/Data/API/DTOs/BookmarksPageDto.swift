//
//  BookmarksPageDto.swift
//  readeck
//
//  Created by Ilyas Hallak on 01.07.25.
//

struct BookmarksPageDto {
    let bookmarks: [BookmarkDto]
    let currentPage: Int?
    let totalCount: Int?
    let totalPages: Int?
    let links: [String]?
}
