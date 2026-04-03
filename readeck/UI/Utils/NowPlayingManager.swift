import Foundation
import MediaPlayer
import UIKit

class NowPlayingManager {
    static let shared = NowPlayingManager()
    private let commandCenter = MPRemoteCommandCenter.shared()
    private var ttsManager: TTSManager { .shared }
    private var speechQueue: SpeechQueue { .shared }
    private var artworkCache: [String: MPMediaItemArtwork] = [:]

    private init() {
        setupRemoteCommands()
    }

    // MARK: - Remote Commands

    private func setupRemoteCommands() {
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.ttsManager.resume()
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
            if let cached = artworkCache[imageUrl] {
                info[MPMediaItemPropertyArtwork] = cached
            } else {
                loadArtwork(from: url) { [weak self] artwork in
                    if let artwork {
                        self?.artworkCache[imageUrl] = artwork
                        var updatedInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                        updatedInfo[MPMediaItemPropertyArtwork] = artwork
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
                    }
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

    private func loadArtwork(from url: URL, completion: @escaping (MPMediaItemArtwork?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            DispatchQueue.main.async { completion(artwork) }
        }.resume()
    }
}
