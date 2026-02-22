# SwiftAudioPlayerKit

A lightweight Swift audio player SDK for iOS, built with `AVPlayer` and SwiftUI.

It includes:
- `AudioPlayerController` for playback state and control
- `AudioControlView` for ready-to-use playback UI
- `WaveformView` for interactive waveform rendering and scrubbing
- `WaveformDataFactory` for default random/placeholder waveform bars

## What This SDK Provides

`SwiftAudioPlayerKit` is a focused, drop-in audio playback toolkit for iOS apps that need:
- Stream or local URL playback through `AVPlayer`
- A prebuilt SwiftUI control surface (`AudioControlView`)
- Interactive scrubbing using a waveform (`WaveformView`)
- Playback speed cycling, +/-15 second seek controls, and progress tracking
- Optional lock-screen metadata and remote command integration

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
        let source = AudioSource(url: url, metadata: AudioMetadata(title: "Sample Audio", artist: "Demo"))
        _controller = StateObject(wrappedValue: AudioPlayerController(audioSource: source))
    }

    var body: some View {
        AudioControlView(controller: controller)
            .padding()
    }
}
```

## Customization Guide

### 1) Audio Source
- Set any playable `URL` via `AudioSource(url:)`
- Set optional resume point with `initialProgressPercent`
- Set lock-screen metadata with `AudioMetadata(title:, artist:)`

### 2) Playback Behavior (`AudioPlayerConfiguration`)
- `supportedPlaybackSpeeds`: controls the speed cycle list in the UI
- `completionThreshold`: defines when completion-threshold delegate callback fires
- `enableRemoteCommands`: enables/disables Control Center and lock-screen command handling
- `enableNowPlayingInfo`: enables/disables lock-screen now-playing metadata updates

### 3) Player UI Styling (`AudioControlViewStyle`)
- `backgroundColor`
- `iconColor`
- `timeTextColor`
- `speedBackgroundColor`
- `speedTextColor`

### 4) Waveform Data and Appearance
- In `AudioControlView`, pass `waveformBars` to render custom waveform samples
- Omit `waveformBars` to use generated default bars
- Pass an empty array to safely show placeholders
- In `WaveformView` (direct usage), customize:
  - `barSpacing`
  - `maxBarHeight`
  - `barColor`
  - `progressColor`

### 5) Runtime Playback Control (`AudioPlayerController`)
- `play()`, `pause()`
- `seek(to:)`
- `seekBackward15Seconds()`, `seekForward15Seconds()`
- `cyclePlaybackSpeed()`
- `updateAudioSource(_:)` to swap tracks
- `captureAudioProgress()` for persistence
- `loadSavedProgress(progressPercent:)` for restoration

### 6) Playback Events (`AudioPlayerControllerDelegate`)
- `audioPlayerReadyToPlay`
- `audioPlayerDidStartPlaying`
- `audioPlayerDidReachCompletionThreshold`
- `audioPlayerDidFinishPlayback`

### Current Limits
- Control layout and button set in `AudioControlView` are fixed unless you build your own UI around `AudioPlayerController`
- Seek step is fixed at 15 seconds in built-in controls
- No built-in playlist/queue management
- No built-in artwork support in now-playing metadata

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

## Build (CLI)

```bash
xcodebuild \
  -project SwiftAudioPlayerKit.xcodeproj \
  -scheme SwiftAudioPlayerKit \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  build
```

## Notes

- Demo playback uses a public MP3 URL; internet access is required.
- Lock screen/remote command behavior is configurable via `AudioPlayerConfiguration`.

## License

Recommended for public SDK distribution: `MIT`.
