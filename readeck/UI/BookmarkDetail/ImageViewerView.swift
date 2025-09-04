import SwiftUI

struct ImageViewerView: View {
    let imageUrl: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var isDraggingToDismiss = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    
                    CachedAsyncImage(url: URL(string: imageUrl))
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .offset(dragOffset)
                        .opacity(isDraggingToDismiss ? 0.8 : 1.0)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = min(max(scale * delta, 1), 4)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                        if scale < 1 {
                                            withAnimation(.spring()) {
                                                scale = 1
                                                offset = .zero
                                            }
                                        }
                                        if scale > 4 {
                                            scale = 4
                                        }
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1 {
                                            let newOffset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                            offset = newOffset
                                        } else {
                                            // Dismiss gesture when not zoomed
                                            dragOffset = value.translation
                                            let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                                            if dragDistance > 50 {
                                                isDraggingToDismiss = true
                                            }
                                        }
                                    }
                                    .onEnded { value in
                                        if scale <= 1 {
                                            lastOffset = offset
                                            let dragDistance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                                            let velocity = sqrt(pow(value.velocity.width, 2) + pow(value.velocity.height, 2))
                                            
                                            if dragDistance > 100 || velocity > 500 {
                                                dismiss()
                                            } else {
                                                withAnimation(.spring()) {
                                                    dragOffset = .zero
                                                    isDraggingToDismiss = false
                                                }
                                            }
                                        } else {
                                            lastOffset = offset
                                        }
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if scale > 1 {
                                    scale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2
                                }
                            }
                        }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }
}
