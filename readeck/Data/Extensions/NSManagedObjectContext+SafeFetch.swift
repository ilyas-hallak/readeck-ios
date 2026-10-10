//
//  NSManagedObjectContext+SafeFetch.swift
//  readeck
//
//  Created by Ilyas Hallak on 25.07.25.
//
//  SPDX-License-Identifier: MIT
//
//  This file is part of the readeck project and is licensed under the MIT License.
//

import CoreData
import Foundation

extension NSManagedObjectContext {
    /// Thread-safe fetch that automatically wraps the operation in performAndWait
    func safeFetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T] {
        // performAndWait blocks the caller, so the request is never used from two threads.
        nonisolated(unsafe) let request = request
        return try performAndWait {
            try self.fetch(request)
        }
    }

    /// Thread-safe perform operation, with or without a return value
    func safePerform<T>(_ operation: () throws -> T) throws -> T {
        // performAndWait blocks the caller, so the operation never runs concurrently with it.
        try withoutActuallyEscaping(operation) { operation in
            nonisolated(unsafe) let operation = operation
            return try performAndWait {
                try operation()
            }
        }
    }
}
