import SwiftUI

public struct WaveformView: View {
    private let barSpacing: CGFloat
    private let maxBarHeight: CGFloat
    private let barColor: Color
    private let progressColor: Color

    public let progress: Double
    public let duration: Double
    public let onSeek: (Double) -> Void
    public let barHeights: [CGFloat]

    public init(
        progress: Double,
        duration: Double,
        barHeights: [CGFloat],
        barSpacing: CGFloat = 5,
        maxBarHeight: CGFloat = 35,
        barColor: Color = .gray.opacity(0.45),
        progressColor: Color = .accentColor,
        onSeek: @escaping (Double) -> Void
    ) {
        self.progress = min(max(progress, 0), 1)
        self.duration = max(duration, 0)
        self.barHeights = barHeights
        self.barSpacing = barSpacing
        self.maxBarHeight = maxBarHeight
        self.barColor = barColor
        self.progressColor = progressColor
        self.onSeek = onSeek
    }

    public var body: some View {
        GeometryReader { geometry in
            let bars = barHeights.isEmpty
                ? WaveformDataFactory.placeholderBars(count: 40, maxHeight: maxBarHeight)
                : barHeights

            let totalWidth = geometry.size.width
            let barCount = bars.count
            let barWidth = barCount > 0
                ? max((totalWidth - barSpacing * CGFloat(barCount - 1)) / CGFloat(barCount), 1)
                : 1

            HStack(spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    Rectangle()
                        .fill(Double(index) / Double(max(barCount, 1)) < progress ? progressColor : barColor)
                        .frame(width: barWidth, height: bars[index])
                        .clipShape(RoundedRectangle(cornerRadius: barWidth / 2, style: .continuous))
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let ratio = min(max(value.location.x / max(totalWidth, 1), 0), 1)
                        onSeek(ratio * duration)
                    }
            )
        }
        .frame(height: maxBarHeight)
    }
}
