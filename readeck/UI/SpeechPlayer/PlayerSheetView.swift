import SwiftUI

struct PlayerSheetView: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    @State private var seekPosition: Double? = nil
    @State private var isSeeking = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                playerHeader
                seekBar
                transportControls
                speedAndVolume
                queueSection
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Header with cover art

    @ViewBuilder
    private var playerHeader: some View {
        VStack(spacing: 12) {
            // Cover image
            if let imageUrl = viewModel.queueItems.first?.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    coverPlaceholder
                }
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)
            } else {
                coverPlaceholder
            }

            // Title + source
            Text(viewModel.queueItems.first?.title ?? "")
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 20)

            if let url = viewModel.queueItems.first?.url,
               let host = URL(string: url)?.host {
                Text(host)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray5))
            .frame(width: 200, height: 200)
            .overlay(
                Image(systemName: "book.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
            )
    }

    // MARK: - Seek Bar

    @ViewBuilder
    private var seekBar: some View {
        VStack(spacing: 4) {
            Slider(
                value: Binding(
                    get: { seekPosition ?? viewModel.articleProgress },
                    set: { newValue in
                        seekPosition = newValue
                        isSeeking = true
                    }
                ),
                in: 0...1,
                onEditingChanged: { editing in
                    if !editing, let position = seekPosition {
                        viewModel.seekToPosition(position)
                        seekPosition = nil
                        isSeeking = false
                    }
                }
            )
            .accentColor(.accentColor)

            HStack {
                Text(formatTime(viewModel.estimatedCurrentTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                Spacer()
                Text(formatTime(viewModel.estimatedDuration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Transport Controls

    @ViewBuilder
    private var transportControls: some View {
        HStack(spacing: 40) {
            // 30s back
            Button(action: { viewModel.seekBack() }) {
                Image(systemName: "gobackward.30")
                    .font(.title2)
                    .foregroundColor(.primary)
            }

            // Play/Pause
            Button(action: {
                if viewModel.isSpeaking {
                    viewModel.pause()
                } else {
                    viewModel.resume()
                }
            }) {
                Image(systemName: viewModel.isSpeaking ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor)
            }

            // Next article
            Button(action: { viewModel.skipToNext() }) {
                Image(systemName: "forward.end.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.queueCount > 1 ? .primary : .secondary)
            }
            .disabled(viewModel.queueCount <= 1)
        }
    }

    // MARK: - Speed & Volume

    @ViewBuilder
    private var speedAndVolume: some View {
        VStack(spacing: 12) {
            // Speed
            HStack {
                Text("Speed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("Speed", selection: Binding(
                    get: { viewModel.rate },
                    set: { viewModel.setRate($0) }
                )) {
                    ForEach([Float(0.25), 0.5, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0], id: \.self) { value in
                        Text(String(format: "%.2fx", value)).tag(value)
                    }
                }
                .pickerStyle(.menu)
            }

            // Volume
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: Binding(
                    get: { viewModel.volume },
                    set: { viewModel.setVolume($0) }
                ), in: 0...1)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Queue Section

    @ViewBuilder
    private var queueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Queue")
                    .font(.headline)
                Spacer()
                if viewModel.queueCount > 1 {
                    Button("Clear All") {
                        viewModel.clearQueue()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 24)

            List {
                ForEach(Array(viewModel.queueItems.enumerated()), id: \.offset) { index, item in
                    HStack {
                        if index == 0 {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.accentColor)
                                .font(.caption)
                                .frame(width: 24)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                        }
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            if let host = URL(string: item.url)?.host {
                                Text(host)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    viewModel.removeItems(at: offsets)
                }
                .onMove { source, destination in
                    viewModel.moveItems(from: source, to: destination)
                }
            }
            .listStyle(.plain)
            .frame(minHeight: 200)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
