import SwiftUI
import MarkdownUI

/// A custom view that renders Markdown content using the MarkdownUI library.
/// This view encapsulates the Markdown rendering logic, making it easy to swap
/// the underlying Markdown library if needed in the future.
struct MarkdownContentView: View {
    let content: String

    var body: some View {
        Markdown(content)
            .textSelection(.enabled)
    }
}

#Preview {
    ScrollView {
        MarkdownContentView(content: """
# Heading 1

This is a paragraph with **bold** and *italic* text.

## Heading 2

- List item 1
- List item 2
- List item 3

### Heading 3

Another paragraph with [a link](https://example.com).
""")
        .padding()
    }
}
