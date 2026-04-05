import SwiftUI

struct DisableBackSwipeModifier: ViewModifier {
    let isDisabled: Bool
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        if isDisabled {
            content
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                    }
                }
        } else {
            content
        }
    }
}
