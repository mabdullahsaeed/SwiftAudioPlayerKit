# SwiftAudioPlayerKit

A lightweight Swift audio player SDK for iOS, built with `AVPlayer` and SwiftUI.

It includes:
- `AudioPlayerController` for playback state and control
- `AudioControlView` for ready-to-use playback UI
- `WaveformView` for interactive waveform rendering and scrubbing
- `WaveformDataFactory` for default random/placeholder waveform bars

## Requirements

- iOS 18.5+
- Xcode 16.4+
- Swift 5+

## Project Structure

- `SwiftAudioPlayerKit/`
  - Framework source files
- `SwiftAudioPlayerKitDemo/`
  - Demo iOS app target that renders the player UI

## Core Types

- `AudioSource`
  - `url: URL`
  - `initialProgressPercent: Int?`
  - `metadata: AudioMetadata?`
- `AudioMetadata`
  - `title: String?`
  - `artist: String?`
- `AudioPlayerConfiguration`
  - `supportedPlaybackSpeeds`
  - `completionThreshold`
  - `enableRemoteCommands`
  - `enableNowPlayingInfo`

## Quick Start

```swift
import SwiftUI
import SwiftAudioPlayerKit

struct ContentView: View {
    @StateObject private var controller: AudioPlayerController

    init() {
        let url = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!
        let source = AudioSource(
            url: url,
            metadata: AudioMetadata(title: "Sample Audio", artist: "Demo")
        )
        _controller = StateObject(wrappedValue: AudioPlayerController(audioSource: source))
    }

    var body: some View {
        AudioControlView(controller: controller)
            .padding()
    }
}
```

## Waveform Behavior

`AudioControlView` supports both custom and default waveform bars:
- Provide `waveformBars` to render your own waveform samples.
- Omit `waveformBars` to use random bars by default.
- If an empty array is provided, placeholder bars are shown safely.

## Delegate Callbacks

Conform to `AudioPlayerControllerDelegate` to receive playback events:
- Ready to play
- Playback started
- Completion threshold reached
- Playback finished

## Run the Demo

1. Open `SwiftAudioPlayerKit.xcodeproj`.
2. Select scheme `SwiftAudioPlayerKitDemo`.
3. Run on Simulator or device.

## Notes

- Demo playback uses a public MP3 URL; internet access is required.
- Lock screen/remote command behavior is configurable via `AudioPlayerConfiguration`.

## License

Recommended for public SDK distribution: `MIT`.
