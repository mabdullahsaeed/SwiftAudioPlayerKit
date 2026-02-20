import CoreGraphics

public enum WaveformDataFactory {
    public static func randomBars(count: Int = 40, maxHeight: CGFloat = 35, minHeightRatio: CGFloat = 0.2) -> [CGFloat] {
        guard count > 0 else { return [] }
        let minHeight = maxHeight * min(max(minHeightRatio, 0), 1)
        return (0..<count).map { _ in CGFloat.random(in: minHeight...maxHeight) }
    }

    public static func placeholderBars(count: Int = 40, maxHeight: CGFloat = 35) -> [CGFloat] {
        guard count > 0 else { return [] }
        let low = maxHeight * 0.35
        let high = maxHeight * 0.7
        return (0..<count).map { index in
            index.isMultiple(of: 2) ? low : high
        }
    }
}
