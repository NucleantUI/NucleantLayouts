import NucleantUI

/// A `Color` takes whatever it is offered, so the cell offered is the cell
/// it ends up. Each layout must offer one that fits.
func filled(_ proposal: ProposedViewSize, count: Int) -> [Size] {
    Array(repeating: Size(width: proposal.width ?? 0, height: proposal.height ?? 0), count: count)
}

/// Whether any two frames share some area.
func overlapping(_ frames: [Rect]) -> Bool {
    for i in frames.indices {
        for j in frames.indices where j > i {
            let a = frames[i], b = frames[j]
            if min(a.maxX, b.maxX) - max(a.minX, b.minX) > 1e-9,
               min(a.maxY, b.maxY) - max(a.minY, b.minY) > 1e-9 {
                return true
            }
        }
    }
    return false
}

/// Whether two values are equal but for rounding.
func close(_ a: Double, _ b: Double, within tolerance: Double = 1e-9) -> Bool {
    abs(a - b) <= tolerance
}

/// Whether two rects are equal but for rounding.
func close(_ a: Rect, _ b: Rect, within tolerance: Double = 1e-9) -> Bool {
    close(a.minX, b.minX, within: tolerance) && close(a.minY, b.minY, within: tolerance)
        && close(a.width, b.width, within: tolerance) && close(a.height, b.height, within: tolerance)
}
