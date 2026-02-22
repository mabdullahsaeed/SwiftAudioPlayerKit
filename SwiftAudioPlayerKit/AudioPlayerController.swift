import AVFoundation
import Combine
import Foundation
import MediaPlayer

public protocol AudioPlayerControllerDelegate: AnyObject {
    func audioPlayerDidReachCompletionThreshold(_ controller: AudioPlayerController)
    func audioPlayerDidFinishPlayback(_ controller: AudioPlayerController)
    func audioPlayerReadyToPlay(_ controller: AudioPlayerController)
    func audioPlayerDidStartPlaying(_ controller: AudioPlayerController)
}

public struct AudioSource {
    public let url: URL
    public let initialProgressPercent: Int?
    public let metadata: AudioMetadata?

    public init(url: URL, initialProgressPercent: Int? = nil, metadata: AudioMetadata? = nil) {
        self.url = url
        self.initialProgressPercent = initialProgressPercent
        self.metadata = metadata
    }
}

public struct AudioMetadata {
    public let title: String?
    public let artist: String?

    public init(title: String? = nil, artist: String? = nil) {
        self.title = title
        self.artist = artist
    }
}

public struct AudioPlayerConfiguration {
    public let supportedPlaybackSpeeds: [Double]
    public let completionThreshold: Double
    public let enableRemoteCommands: Bool
    public let enableNowPlayingInfo: Bool

    public init(supportedPlaybackSpeeds: [Double] = [1.0, 1.25, 1.5, 1.75, 2.0], completionThreshold: Double = 0.9, enableRemoteCommands: Bool = true, enableNowPlayingInfo: Bool = true) {
        self.supportedPlaybackSpeeds = supportedPlaybackSpeeds
        self.completionThreshold = min(max(completionThreshold, 0.0), 1.0)
        self.enableRemoteCommands = enableRemoteCommands
        self.enableNowPlayingInfo = enableNowPlayingInfo
    }
}

@MainActor
public final class AudioPlayerController: ObservableObject {
    @Published public private(set) var currentTime: Double = 0
    @Published public private(set) var duration: Double = 0
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var playbackSpeed: Double = 1.0

    public weak var delegate: AudioPlayerControllerDelegate?

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var rateObserver: NSKeyValueObservation?
    private var statusObserver: NSKeyValueObservation?
    private var didConfigureRemoteCommands = false
    private var didReachCompletionThreshold = false

    private var audioSource: AudioSource
    private let configuration: AudioPlayerConfiguration

    public init(audioSource: AudioSource, configuration: AudioPlayerConfiguration = .init()) {
        self.audioSource = audioSource
        self.configuration = configuration
        self.playbackSpeed = configuration.supportedPlaybackSpeeds.first ?? 1.0

        setupAudioSession()
        setupPlayer(with: audioSource.url)

        if configuration.enableRemoteCommands {
            setupRemoteCommandCenter()
        }

        if configuration.enableNowPlayingInfo {
            setupNowPlaying()
        }
    }

    deinit {
        Task { @MainActor [weak self] in
            self?.cleanUp()
        }
    }

    public func play() {
        player?.play()
        player?.rate = Float(playbackSpeed)
        delegate?.audioPlayerDidStartPlaying(self)
    }

    public func pause() {
        player?.pause()
    }

    public func seek(to time: Double) {
        let clampedTime = min(max(time, 0), duration)
        let cmTime = CMTime(seconds: clampedTime, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }

    public func seekBackward15Seconds() {
        seek(to: currentTime - 15)
    }

    public func seekForward15Seconds() {
        seek(to: currentTime + 15)
    }

    public func cyclePlaybackSpeed() {
        guard !configuration.supportedPlaybackSpeeds.isEmpty else { return }

        if let currentIndex = configuration.supportedPlaybackSpeeds.firstIndex(of: playbackSpeed) {
            let nextIndex = (currentIndex + 1) % configuration.supportedPlaybackSpeeds.count
            playbackSpeed = configuration.supportedPlaybackSpeeds[nextIndex]
        } else {
            playbackSpeed = configuration.supportedPlaybackSpeeds[0]
        }

        if isPlaying {
            player?.rate = Float(playbackSpeed)
            updateNowPlaying()
        }
    }

    public func captureAudioProgress() -> Double? {
        guard duration > 0, currentTime > 1.0 else { return nil }
        return (currentTime / duration).roundedToTwoDecimals()
    }

    public func loadSavedProgress(progressPercent: Int) {
        guard progressPercent > 0, progressPercent < 100, duration > 0 else { return }
        let savedTime = (Double(progressPercent) / 100.0) * duration
        seek(to: savedTime)
    }

    public func updateAudioSource(_ newSource: AudioSource) {
        tearDownPlayerState()
        audioSource = newSource
        didReachCompletionThreshold = false

        currentTime = 0
        duration = 0
        isPlaying = false

        setupPlayer(with: newSource.url)
        if configuration.enableNowPlayingInfo {
            setupNowPlaying()
        }
    }

    public func cleanUp() {
        pause()
        tearDownPlayerState()
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())

        currentTime = 0
        duration = 0
        isPlaying = false
        playbackSpeed = configuration.supportedPlaybackSpeeds.first ?? 1.0
        didReachCompletionThreshold = false
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleInterruption),
                name: AVAudioSession.interruptionNotification,
                object: AVAudioSession.sharedInstance()
            )
        } catch {
            print("AudioPlayerController setupAudioSession error: \(error)")
        }
    }

    private func setupPlayer(with url: URL) {
        let item = AVPlayerItem(url: url)
        playerItem = item
        player = AVPlayer(playerItem: item)

        Task {
            do {
                let loadedDuration = try await item.asset.load(.duration).seconds
                if loadedDuration.isFinite {
                    duration = loadedDuration
                }
            } catch {
                print("AudioPlayerController load duration error: \(error)")
            }
        }

        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self else { return }

                self.currentTime = time.seconds
                self.updateNowPlaying()

                let progress = self.duration > 0 ? self.currentTime / self.duration : 0
                if !self.didReachCompletionThreshold, progress >= self.configuration.completionThreshold {
                    self.didReachCompletionThreshold = true
                    self.delegate?.audioPlayerDidReachCompletionThreshold(self)
                }
            }
        }

        rateObserver = player?.observe(\.rate, options: [.new]) { [weak self] player, _ in
            guard let self else { return }
            Task { @MainActor in
                self.isPlaying = player.rate != 0
                self.updateNowPlaying()
            }
        }

        statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            Task { @MainActor in
                switch item.status {
                case .readyToPlay:
                    if let progressPercent = self.audioSource.initialProgressPercent {
                        self.loadSavedProgress(progressPercent: progressPercent)
                    }
                    self.delegate?.audioPlayerReadyToPlay(self)
                case .failed:
                    print("AudioPlayerController item status failed: \(item.error?.localizedDescription ?? "Unknown error")")
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }

    private func tearDownPlayerState() {
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        rateObserver?.invalidate()
        rateObserver = nil

        statusObserver?.invalidate()
        statusObserver = nil

        if let item = playerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
        }

        playerItem = nil
        player = nil
    }

    @objc private func handleInterruption(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }

        switch type {
        case .began:
            pause()
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    play()
                }
            }
        @unknown default:
            break
        }
    }

    @objc private func playerDidFinishPlaying(_ notification: Notification) {
        isPlaying = false
        currentTime = 0
        seek(to: 0)
        delegate?.audioPlayerDidReachCompletionThreshold(self)
        delegate?.audioPlayerDidFinishPlayback(self)
    }

    private func setupRemoteCommandCenter() {
        guard !didConfigureRemoteCommands else { return }
        didConfigureRemoteCommands = true

        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if !self.isPlaying {
                self.play()
                return .success
            }
            return .commandFailed
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if self.isPlaying {
                self.pause()
                return .success
            }
            return .commandFailed
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.isPlaying ? self.pause() : self.play()
            return .success
        }

        commandCenter.seekForwardCommand.addTarget { [weak self] _ in
            self?.seekForward15Seconds()
            return .success
        }

        commandCenter.seekBackwardCommand.addTarget { [weak self] _ in
            self?.seekBackward15Seconds()
            return .success
        }
    }

    private func setupNowPlaying() {
        guard configuration.enableNowPlayingInfo else { return }

        var info: [String: Any] = [
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? playbackSpeed : 0.0
        ]

        if let title = audioSource.metadata?.title {
            info[MPMediaItemPropertyTitle] = title
        }

        if let artist = audioSource.metadata?.artist {
            info[MPMediaItemPropertyArtist] = artist
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlaying() {
        guard configuration.enableNowPlayingInfo else { return }

        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackSpeed : 0.0

        if let title = audioSource.metadata?.title {
            info[MPMediaItemPropertyTitle] = title
        }

        if let artist = audioSource.metadata?.artist {
            info[MPMediaItemPropertyArtist] = artist
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

private extension Double {
    func roundedToTwoDecimals() -> Double {
        (self * 100).rounded() / 100
    }
}
