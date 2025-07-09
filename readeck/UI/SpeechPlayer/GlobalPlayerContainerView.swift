import SwiftUI

struct GlobalPlayerContainerView<Content: View>: View {
    let content: Content
    @State private var speechQueue = SpeechQueue.shared
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if speechQueue.hasItems {
                VStack(spacing: 0) {
                    SpeechPlayerView()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 49)
                }
            }
        }
        .animation(.spring(), value: speechQueue.hasItems)
    }
}

#Preview {
    GlobalPlayerContainerView {
        Text("Main Content")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
} 
