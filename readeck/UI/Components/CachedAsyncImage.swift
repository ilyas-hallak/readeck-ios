import SwiftUI
import Kingfisher

struct CachedAsyncImage: View {
    let url: URL?
    
    init(url: URL?) {
        self.url = url
    }
    
    var body: some View {
        if let url {
            KFImage(url)
                .placeholder {
                    Color.gray.opacity(0.3)
                }
                .fade(duration: 0.25)
                .resizable()
                .frame(maxWidth: .infinity)
        } else {
            Image("placeholder")
                .resizable()
                .scaledToFill()
        }
    }
}
