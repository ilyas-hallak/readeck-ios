import SwiftUI

struct SpeechPlayerView: View {
    @State var viewModel = SpeechPlayerViewModel()
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    var onClose: (() -> Void)? = nil
    
    private let minHeight: CGFloat = 60
    private let maxHeight: CGFloat = UIScreen.main.bounds.height / 2
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                ExpandedPlayerView(viewModel: viewModel, isExpanded: $isExpanded, onClose: onClose)
            } else {
                CollapsedPlayerBar(viewModel: viewModel, isExpanded: $isExpanded)
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
}

private struct CollapsedPlayerBar: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    @Binding var isExpanded: Bool
    
    var body: some View {
        HStack(spacing: 16) {
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
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentText.isEmpty ? "Keine Wiedergabe" : viewModel.currentText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if viewModel.articleProgress > 0 && viewModel.articleProgress < 1 {
                    ProgressView(value: viewModel.articleProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .scaleEffect(y: 0.8)
                }
                if viewModel.queueCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "text.line.first.and.arrowtriangle.forward")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.currentUtteranceIndex + 1)/\(viewModel.queueCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }.onTapGesture {
                withAnimation(.spring()) { isExpanded.toggle() }
            }
            Spacer()
            Button(action: { viewModel.stop() }) {
                Image(systemName: "stop.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                Image(systemName: "chevron.up")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct ExpandedPlayerView: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    @Binding var isExpanded: Bool
    var onClose: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Button(action: { onClose?() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("Vorlese-Queue")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { withAnimation(.spring()) { isExpanded = false } }) {
                    Image(systemName: "chevron.down")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            // Fortschrittsbalken für aktuellen Artikel
            if viewModel.articleProgress > 0 && viewModel.articleProgress < 1 {
                VStack(spacing: 4) {
                    ProgressView(value: viewModel.articleProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    HStack {
                        Text("Fortschritt: \(Int(viewModel.articleProgress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
            }
            
            PlayerControls(viewModel: viewModel)
            PlayerVolume(viewModel: viewModel)
            
            if viewModel.queueCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "text.line.first.and.arrowtriangle.forward")
                        .foregroundColor(.accentColor)
                    Text("Lese \(viewModel.currentUtteranceIndex + 1)/\(viewModel.queueCount): ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.queueItems[safe: viewModel.currentUtteranceIndex]?.title ?? "")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            PlayerQueueList(viewModel: viewModel)
            Spacer()
        }
    }
}

private struct PlayerControls: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    let rates: [Float] = [0.25, 0.5, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
    var body: some View {
        ZStack {
            HStack {
                Spacer()
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
                    Button(action: { viewModel.stop() }) {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            HStack {
                Spacer()
                Picker("Geschwindigkeit", selection: Binding(
                    get: { viewModel.rate },
                    set: { viewModel.setRate($0) }
                )) {
                    ForEach(rates, id: \ .self) { value in
                        Text(String(format: "%.2fx", value)).tag(Float(value))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 120)
            }
        }
        .padding(.horizontal, 16)
    }
}

private struct PlayerVolume: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.accentColor)
                Slider(value: Binding(
                    get: { viewModel.volume },
                    set: { viewModel.setVolume($0) }
                ), in: 0...1, step: 0.01)
                Text(String(format: "%.0f%%", viewModel.volume * 100))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
    }
}

private struct PlayerRate: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    let rates: [Float] = [0.25, 0.5, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "speedometer")
                    .foregroundColor(.accentColor)
                Picker("Geschwindigkeit", selection: Binding(
                    get: { viewModel.rate },
                    set: { viewModel.setRate($0) }
                )) {
                    ForEach(rates, id: \ .self) { value in
                        Text(String(format: "%.2fx", value)).tag(Float(value))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 120)
            }
        }
        .padding(.horizontal, 16)
    }
}

private struct PlayerQueueList: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    var body: some View {
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
                            Text(item.title)
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
    }
}

// Array safe access helper
fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    SpeechPlayerView()
}
