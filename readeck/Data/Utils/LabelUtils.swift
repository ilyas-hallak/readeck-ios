import Foundation

struct LabelUtils {
    /// Splits a label input string by spaces and returns individual trimmed labels
    /// - Parameter input: The input string containing one or more labels separated by spaces
    /// - Returns: Array of individual trimmed labels, excluding empty strings
    static func splitLabelsFromInput(_ input: String) -> [String] {
        return input
            .components(separatedBy: " ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    /// Filters out labels that already exist in current or available labels
    /// - Parameters:
    ///   - labels: Array of labels to filter
    ///   - currentLabels: Currently selected labels
    ///   - availableLabels: Available labels (optional)
    /// - Returns: Array of unique labels that don't already exist
    static func filterUniqueLabels(_ labels: [String], currentLabels: [String], availableLabels: [String] = []) -> [String] {
        let currentSet = Set(currentLabels.map { $0.lowercased() })
        let availableSet = Set(availableLabels.map { $0.lowercased() })
        
        return labels.filter { label in
            let lowercased = label.lowercased()
            return !currentSet.contains(lowercased) && !availableSet.contains(lowercased)
        }
    }
}