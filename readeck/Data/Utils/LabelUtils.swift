import Foundation

struct LabelUtils {
    /// Processes a label input string and returns it as a single trimmed label
    /// - Parameter input: The input string containing a label (spaces are allowed)
    /// - Returns: Array containing the trimmed label, or empty array if input is empty
    static func splitLabelsFromInput(_ input: String) -> [String] {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? [] : [trimmed]
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