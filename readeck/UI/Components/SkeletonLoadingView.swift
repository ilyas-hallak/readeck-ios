import SwiftUI

struct SkeletonLoadingView: View {
    let layout: CardLayoutStyle
    @State private var animateGradient = false
    
    var body: some View {
        LazyVStack(spacing: layout == .compact ? 8 : 12) {
            ForEach(0..<6, id: \.self) { _ in
                skeletonCard
            }
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                animateGradient = true
            }
        }
    }
    
    @ViewBuilder
    private var skeletonCard: some View {
        switch layout {
        case .compact:
            compactSkeletonCard
        case .magazine:
            magazineSkeletonCard
        case .natural:
            naturalSkeletonCard
        }
    }
    
    private var compactSkeletonCard: some View {
        HStack(alignment: .top, spacing: 12) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(shimmerGradient)
                .frame(width: 80, height: 80)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 180, height: 16)
                
                // Description placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 120, height: 14)
                
                Spacer()
                
                // Bottom info placeholder
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 80, height: 12)
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 50, height: 12)
                }
            }
        }
        .padding(12)
        .background(Color(R.color.bookmark_list_bg))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var magazineSkeletonCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(shimmerGradient)
                .frame(height: 140)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 200, height: 16)
                
                // Info placeholders
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 80, height: 12)
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 60, height: 12)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(R.color.bookmark_list_bg))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var naturalSkeletonCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(shimmerGradient)
                .frame(minHeight: 180)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 220, height: 16)
                
                // Info placeholders
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 90, height: 12)
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 70, height: 12)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(R.color.bookmark_list_bg))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.1),
                Color.gray.opacity(0.3)
            ],
            startPoint: animateGradient ? .topLeading : .topTrailing,
            endPoint: animateGradient ? .bottomTrailing : .bottomLeading
        )
    }
}

#Preview {
    ScrollView {
        SkeletonLoadingView(layout: .magazine)
            .padding()
    }
}