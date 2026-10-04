import Foundation

extension AnnotationMarkup {
    /// JavaScript that reports taps on saved highlights. `report` is a JS function
    /// expression that receives the highlight ID.
    static func tapHandlerScript(report: String) -> String {
        """
        (function() {
            const report = \(report);
            document.querySelectorAll('rd-annotation[data-annotation-id-value]').forEach(el => {
                el.addEventListener('click', (event) => {
                    const id = el.getAttribute('data-annotation-id-value');
                    // Links keep working, and a running text selection wins over the tap.
                    if (event.target.closest('a') || !window.getSelection().isCollapsed) return;
                    // Fresh highlights carry a temporary ID until the article reloads.
                    if (!id || id.startsWith('temp-')) return;
                    report(id);
                });
            });
        })();
        """
    }
}
