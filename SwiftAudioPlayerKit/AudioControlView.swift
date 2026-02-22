import SwiftUI

public struct AudioControlViewStyle {
    public let backgroundColor: Color
    public let iconColor: Color
    public let timeTextColor: Color
    public let speedBackgroundColor: Color
    public let speedTextColor: Color

    public init(backgroundColor: Color = Color.black.opacity(0.85), iconColor: Color = .white, timeTextColor: Color = .gray, speedBackgroundColor: Color = Color.gray.opacity(0.25), speedTextColor: Color = .white) {
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
        self.timeTextColor = timeTextColor
        self.speedBackgroundColor = speedBackgroundColor
        self.speedTextColor = speedTextColor
    }
}

public struct AudioControlView: View {
    @StateObject private var controller: AudioPlayerController
    @State private var generatedBars: [CGFloat] = []

    private let waveformBars: [CGFloat]?
    private let style: AudioControlViewStyle

    public init(controller: AudioPlayerController, waveformBars: [CGFloat]? = nil, style: AudioControlViewStyle = .init()) {
        _controller = StateObject(wrappedValue: controller)
        self.waveformBars = waveformBars
        self.style = style
    }

    private var resolvedBars: [CGFloat] {
        if let waveformBars {
            return waveformBars.isEmpty ? WaveformDataFactory.placeholderBars(count: 40, maxHeight: 35) : waveformBars
        }

        if generatedBars.isEmpty {
            return WaveformDataFactory.placeholderBars(count: 40, maxHeight: 35)
        }

        return generatedBars
    }

    public var body: some View {
        VStack(spacing: 0) {
            WaveformView(progress: controller.duration > 0 ? controller.currentTime / controller.duration : 0, duration: controller.duration, barHeights: resolvedBars, onSeek: { controller.seek(to: $0) })
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 8)
            .onAppear {
                if waveformBars == nil, generatedBars.isEmpty {
                    generatedBars = WaveformDataFactory.randomBars(count: 40, maxHeight: 35)
                }
            }

            HStack {
                Text(timeString(from: controller.currentTime))
                    .font(.caption)
                    .foregroundColor(style.timeTextColor)
                Spacer()
                Text(timeString(from: controller.duration))
                    .font(.caption)
                    .foregroundColor(style.timeTextColor)
            }
            .padding(.horizontal, 16)

            ZStack {
                HStack(spacing: 30) {
                    Button(action: { controller.seekBackward15Seconds() }) {
                        Image(systemName: "gobackward.15")
                            .font(.title3)
                            .foregroundStyle(style.iconColor)
                    }

                    Button(action: {
                        controller.isPlaying ? controller.pause() : controller.play()
                    }) {
                        Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .foregroundStyle(style.iconColor)
                    }

                    Button(action: { controller.seekForward15Seconds() }) {
                        Image(systemName: "goforward.15")
                            .font(.title3)
                            .foregroundStyle(style.iconColor)
                    }
                }
                .frame(maxWidth: .infinity)

                HStack {
                    Spacer()
                    Button(action: { controller.cyclePlaybackSpeed() }) {
                        Text("\(String(format: "%.2fx", controller.playbackSpeed))")
                            .font(.caption)
                            .foregroundColor(style.speedTextColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(style.speedBackgroundColor)
                            .clipShape(Capsule())
                    }
                }
                .padding(.trailing, 16)
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .frame(maxHeight: 145)
        .background(style.backgroundColor)
    }

    private func timeString(from seconds: Double) -> String {
        guard !seconds.isNaN, !seconds.isInfinite else { return "00:00" }
        let totalSeconds = Int(seconds.rounded())
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
