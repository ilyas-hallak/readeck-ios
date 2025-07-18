//
//  File.swift
//  readeck
//
//  Created by Ilyas Hallak on 18.07.25.
//

extension String: @retroactive Identifiable {
    public var id: String { self }
}
