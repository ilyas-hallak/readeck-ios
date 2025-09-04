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
        var results: [T] = []
        var fetchError: Error?
        
        performAndWait {
            do {
                results = try self.fetch(request)
            } catch {
                fetchError = error
            }
        }
        
        if let error = fetchError {
            throw error
        }
        
        return results
    }
    
    /// Thread-safe perform operation with return value
    func safePerform<T>(_ operation: @escaping @Sendable () throws -> T) throws -> T {
        var result: T?
        var operationError: Error?
        
        performAndWait {
            do {
                result = try operation()
            } catch {
                operationError = error
            }
        }
        
        if let error = operationError {
            throw error
        }
        
        guard let unwrappedResult = result else {
            throw NSError(domain: "SafePerformError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Operation returned nil"])
        }
        
        return unwrappedResult
    }
    
    /// Thread-safe perform operation without return value
    func safePerform(_ operation: @escaping () throws -> Void) throws {
        var operationError: Error?
        
        performAndWait {
            do {
                try operation()
            } catch {
                operationError = error
            }
        }
        
        if let error = operationError {
            throw error
        }
    }
}