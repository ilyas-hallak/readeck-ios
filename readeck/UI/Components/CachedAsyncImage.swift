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
                .requestModifier(AuthenticatedImageRequestModifier())
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

/// Request modifier that adds Authorization header and custom headers to image requests
struct AuthenticatedImageRequestModifier: ImageDownloadRequestModifier {
    func modified(for request: URLRequest) -> URLRequest? {
        var modifiedRequest = request
        
        if let token = KeychainHelper.shared.loadToken() {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        HTTPHeadersHelper.shared.applyCustomHeaders(to: &modifiedRequest)
        
        return modifiedRequest
    }
}
