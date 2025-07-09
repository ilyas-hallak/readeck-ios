import SwiftUI

struct SpeechPlayerView: View {
    @State var viewModel = SpeechPlayerViewModel()
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    
    private let minHeight: CGFloat = 60
    private let maxHeight: CGFloat = 300
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedView
            } else {
                collapsedView
            }
        }
        .frame(height: isExpanded ? maxHeight : minHeight)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 8, x: 0, y: -2)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    withAnimation(.spring()) {
                        if value.translation.height < -50 && !isExpanded {
                            isExpanded = true
                        } else if value.translation.height > 50 && isExpanded {
                            isExpanded = false
                        }
                        dragOffset = 0
                    }
                }
        )
    }
    
    private var collapsedView: some View {
        HStack(spacing: 16) {
            // Play/Pause Button
            Button(action: {
                if viewModel.isSpeaking {
                    viewModel.pause()
                } else {
                    viewModel.resume()
                }
            }) {
                Image(systemName: viewModel.isSpeaking ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            
            // Current Text
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentText.isEmpty ? "Keine Wiedergabe" : viewModel.currentText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if viewModel.queueCount > 0 {
                    Text("\(viewModel.queueCount) Artikel in Queue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }.onTapGesture {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
            
            Spacer()
            
            // Stop Button
            Button(action: {
                viewModel.stop()
            }) {
                Image(systemName: "stop.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Expand Button
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: "chevron.up")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var expandedView: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Vorlese-Queue")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "chevron.down")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Controls
            HStack(spacing: 24) {
                Button(action: {
                    if viewModel.isSpeaking {
                        viewModel.pause()
                    } else {
                        viewModel.resume()
                    }
                }) {
                    Image(systemName: viewModel.isSpeaking ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.accentColor)
                }
                
                Button(action: {
                    viewModel.stop()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Queue List
            if viewModel.queueCount == 0 {
                Text("Keine Artikel in der Queue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(viewModel.queueItems.enumerated()), id: \.offset) { index, item in
                            HStack {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, alignment: .leading)
                                
                                Text(item)
                                    .font(.subheadline)
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    SpeechPlayerView()
}
