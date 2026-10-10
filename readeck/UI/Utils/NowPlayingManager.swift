import Foundation
import MediaPlayer
import UIKit

@MainActor
final class NowPlayingManager {
    static let shared = NowPlayingManager()
    private let commandCenter = MPRemoteCommandCenter.shared()
    private var ttsManager: TTSManager { .shared }
    private var speechQueue: SpeechQueue { .shared }
    private let artworkCache = NSCache<NSString, MPMediaItemArtwork>()

    private init() {
        artworkCache.countLimit = 20
        setupRemoteCommands()
    }

    // MARK: - Remote Commands

    private func setupRemoteCommands() {
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.speechQueue.resumeOrReplay()
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.ttsManager.pause()
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.speechQueue.skipToNext()
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.ttsManager.seekBack(seconds: 30)
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            let cps = self?.ttsManager.estimatedCharactersPerSecond() ?? 15
            let targetChar = Int(positionEvent.positionTime * cps)
            self?.ttsManager.seek(toCharacter: targetChar)
            return .success
        }
    }

    // MARK: - Now Playing Info

    func updateNowPlayingInfo(title: String, source: String?, imageUrl: String?, duration: TimeInterval, currentTime: TimeInterval) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]

        if let source {
            info[MPMediaItemPropertyArtist] = source
        }

        // Load artwork (cached)
        if let imageUrl, let url = URL(string: imageUrl) {
            let cacheKey = imageUrl as NSString
            if let cached = artworkCache.object(forKey: cacheKey) {
                info[MPMediaItemPropertyArtwork] = cached
            } else {
                Task { [weak self] in
                    guard let image = await Self.loadArtworkImage(from: url) else { return }
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    self?.artworkCache.setObject(artwork, forKey: cacheKey)
                    var updatedInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                    updatedInfo[MPMediaItemPropertyArtwork] = artwork
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
                }
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func updateNowPlayingPlaybackState(isPlaying: Bool) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = ttsManager.estimatedCurrentTime()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func updateNowPlayingPosition() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = ttsManager.estimatedCurrentTime()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Artwork Loading

    private nonisolated static func loadArtworkImage(from url: URL) async -> UIImage? {
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return UIImage(data: data)
    }
}
