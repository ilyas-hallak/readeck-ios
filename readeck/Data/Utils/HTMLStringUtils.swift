import Foundation

enum HTMLStringUtils {

    static func stripHTML(_ html: String) -> String {
        var text = html
        // Remove script and style blocks
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        // Replace <br>, <p>, <div> with newlines
        text = text.replacingOccurrences(of: "<br[^>]*>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</p>", with: "\n\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</div>", with: "\n", options: .regularExpression)
        // Remove all remaining tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        // Decode common HTML entities
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        // Collapse multiple newlines
        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static let maxChunkCharacters = 12_000

    static func splitIntoChunks(text: String, maxCharacters: Int = maxChunkCharacters) -> [String] {
        let paragraphs = text.components(separatedBy: "\n\n")
        var chunks: [String] = []
        var currentChunk = ""

        for paragraph in paragraphs {
            if currentChunk.count + paragraph.count + 2 > maxCharacters {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk)
                    currentChunk = ""
                }
                if paragraph.count > maxCharacters {
                    let sentences = paragraph.components(separatedBy: ". ")
                    for sentence in sentences {
                        if currentChunk.count + sentence.count + 2 > maxCharacters {
                            if !currentChunk.isEmpty {
                                chunks.append(currentChunk)
                                currentChunk = ""
                            }
                        }
                        currentChunk += (currentChunk.isEmpty ? "" : ". ") + sentence
                    }
                } else {
                    currentChunk = paragraph
                }
            } else {
                currentChunk += (currentChunk.isEmpty ? "" : "\n\n") + paragraph
            }
        }
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        return chunks
    }
}
