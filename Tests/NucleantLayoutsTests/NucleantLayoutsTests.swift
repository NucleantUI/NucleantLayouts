import Foundation
import NucleantUI
import Testing
@testable import NucleantLayouts

/// Each layout's arrangement — the frames it gives subviews of given
/// sizes, and its own size — checked against positions worked out by hand.
@MainActor
@Suite
struct Arrangements {
    let square = Size(width: 10, height: 10)

    func center(_ rect: Rect) -> Point { rect.center }

    // MARK: Circular

    @Test
    func circularStartsAtTheTopAndGoesClockwise() {
        let result = CircularLayout(radius: 50).arrangement(of: Array(repeating: square, count: 4), in: .unspecified)
        // The circle plus the largest subview, whatever was offered.
        #expect(result.size == Size(width: 110, height: 110))
        let centers = result.frames.map(center)
        #expect(abs(centers[0].x - 55) < 1e-9 && abs(centers[0].y - 5) < 1e-9)    // top
        #expect(abs(centers[1].x - 105) < 1e-9 && abs(centers[1].y - 55) < 1e-9)  // right
        #expect(abs(centers[2].x - 55) < 1e-9 && abs(centers[2].y - 105) < 1e-9)  // bottom
        #expect(abs(centers[3].x - 5) < 1e-9 && abs(centers[3].y - 55) < 1e-9)    // left
        #expect(result.frames.allSatisfy { $0.size == square })
    }

    @Test
    func circularStartAngleTurnsEverySubview() {
        let result = CircularLayout(radius: 50, startAngle: .degrees(0)).arrangement(of: [square, square], in: .unspecified)
        let centers = result.frames.map(center)
        #expect(abs(centers[0].x - 105) < 1e-9 && abs(centers[0].y - 55) < 1e-9)
        #expect(abs(centers[1].x - 5) < 1e-9 && abs(centers[1].y - 55) < 1e-9)
    }

    @Test
    func circularWithNothingIsEmpty() {
        let result = CircularLayout(radius: 50).arrangement(of: [], in: .unspecified)
        #expect(result.frames.isEmpty)
        #expect(result.size == .zero)
    }

    // MARK: Grid

    @Test
    func gridFillsRowsLeftToRight() {
        let result = GridLayout(columns: 3).arrangement(
            of: Array(repeating: square, count: 5),
            gaps: Size(width: 2, height: 2)
        )
        #expect(result.size == Size(width: 34, height: 22))
        #expect(result.frames[2].origin == Point(x: 24, y: 0))
        #expect(result.frames[3].origin == Point(x: 0, y: 12))
        #expect(result.frames[4].origin == Point(x: 12, y: 12))
    }

    @Test
    func gridSizesColumnsAndRowsByTheirLargestCell() {
        let sizes = [Size(width: 30, height: 10), Size(width: 10, height: 10), Size(width: 10, height: 40)]
        let result = GridLayout(columns: 2).arrangement(of: sizes, gaps: .zero)
        // Column 0 is 30 wide; row 1 is 40 tall.
        #expect(result.size == Size(width: 40, height: 50))
        // A narrow cell in the wide column, centred in its slot.
        #expect(result.frames[2].origin == Point(x: 10, y: 10))
    }

    @Test
    func gridAlignsASmallerCellInItsSlot() {
        let sizes = [Size(width: 20, height: 20), Size(width: 10, height: 10)]
        let top = GridLayout(columns: 2, alignment: .topLeading).arrangement(of: sizes, gaps: .zero)
        let bottom = GridLayout(columns: 2, alignment: .bottomTrailing).arrangement(of: sizes, gaps: .zero)
        #expect(top.frames[1].origin == Point(x: 20, y: 0))
        #expect(bottom.frames[1].origin == Point(x: 20, y: 10))
    }

    // MARK: Flow

    @Test
    func flowWrapsWhenTheNextWouldNotFit() {
        let sizes = Array(repeating: Size(width: 40, height: 10), count: 3)
        let result = FlowLayout().arrangement(of: sizes, width: 100, gaps: Size(width: 10, height: 5))
        #expect(result.frames[1].origin == Point(x: 50, y: 0))
        #expect(result.frames[2].origin == Point(x: 0, y: 15))
        // Takes the width it was offered.
        #expect(result.size == Size(width: 100, height: 25))
    }

    @Test
    func flowAlignsEachLine() {
        let sizes = Array(repeating: Size(width: 40, height: 10), count: 3)
        let gaps = Size(width: 10, height: 5)
        let centered = FlowLayout(alignment: .center).arrangement(of: sizes, width: 100, gaps: gaps)
        let trailing = FlowLayout(alignment: .trailing).arrangement(of: sizes, width: 100, gaps: gaps)
        #expect(centered.frames[0].origin.x == 5)
        #expect(centered.frames[2].origin.x == 30)
        #expect(trailing.frames[2].origin.x == 60)
    }

    @Test
    func flowWithNoWidthIsOneLine() {
        let sizes = Array(repeating: Size(width: 40, height: 10), count: 3)
        let result = FlowLayout().arrangement(of: sizes, width: nil, gaps: Size(width: 10, height: 5))
        #expect(result.frames.allSatisfy { $0.origin.y == 0 })
        #expect(result.size == Size(width: 140, height: 10))
    }

    @Test
    func flowCentresShorterSubviewsOnTheirLine() {
        let sizes = [Size(width: 10, height: 30), Size(width: 10, height: 10)]
        let result = FlowLayout().arrangement(of: sizes, width: 100, gaps: .zero)
        #expect(result.frames[1].origin == Point(x: 10, y: 10))
    }

    // MARK: Masonry

    @Test
    func masonryDropsEachIntoTheShortestColumn() {
        let result = MasonryLayout(columns: 2).arrangement(
            of: [100, 50, 30],
            columnWidth: 40,
            gaps: Size(width: 10, height: 10)
        )
        #expect(result.frames[0] == Rect(x: 0, y: 0, width: 40, height: 100))
        #expect(result.frames[1] == Rect(x: 50, y: 0, width: 40, height: 50))
        #expect(result.frames[2] == Rect(x: 50, y: 60, width: 40, height: 30))
        #expect(result.size == Size(width: 90, height: 100))
    }

    @Test
    func masonryTakesTheLeftmostOfEqualColumns() {
        let result = MasonryLayout(columns: 3).arrangement(of: [10, 10, 10, 10], columnWidth: 10, gaps: .zero)
        #expect(result.frames.map(\.origin) == [
            Point(x: 0, y: 0), Point(x: 10, y: 0), Point(x: 20, y: 0), Point(x: 0, y: 10),
        ])
    }

    // MARK: Honeycomb

    @Test
    func honeycombAlternatesLongAndShortRows() {
        let result = HoneycombLayout(columns: 3, spacing: 0).arrangement(count: 5, cell: Size(width: 20, height: 20))
        // The short row is pushed in by half a cell and up by a quarter.
        #expect(result.frames[2].origin == Point(x: 40, y: 0))
        #expect(result.frames[3].origin == Point(x: 10, y: 15))
        #expect(result.frames[4].origin == Point(x: 30, y: 15))
        #expect(result.size == Size(width: 60, height: 35))
    }

    @Test
    func honeycombOfOneColumnZigzags() {
        let result = HoneycombLayout(columns: 1, spacing: 0).arrangement(count: 3, cell: Size(width: 20, height: 20))
        #expect(result.frames.map(\.origin) == [Point(x: 0, y: 0), Point(x: 10, y: 15), Point(x: 0, y: 30)])
        #expect(result.size == Size(width: 30, height: 50))
    }

    // MARK: Spiral

    @Test
    func spiralNeighboursDoNotOverlapAtTheDefaultSpacing() {
        let diameter = 20.0
        let result = SpiralLayout().arrangement(of: Array(repeating: Size(width: diameter, height: diameter), count: 120))
        let centers = result.frames.map(center)
        var closest = Double.infinity
        for i in centers.indices {
            for j in centers.indices where j > i {
                let d = centers[i] - centers[j]
                closest = min(closest, (d.x * d.x + d.y * d.y).squareRoot())
            }
        }
        #expect(closest >= diameter)
    }

    // MARK: Flexible subviews

    @Test
    func honeycombOffersTheCellThatFitsItsSpace() {
        let layout = HoneycombLayout(columns: 2, spacing: 4)
        let offered = ProposedViewSize(width: 640, height: 480)
        let cell = layout.cellProposal(count: 4, offered: offered)
        let size = layout.arrangement(count: 4, cell: Size(width: cell.width!, height: cell.height!)).size
        #expect(size.width <= 640 + 1e-9 && size.height <= 480 + 1e-9)
        // As big as it can be: one side fills.
        #expect(abs(size.width - 640) < 1e-9 || abs(size.height - 480) < 1e-9)
        #expect(abs(cell.height! - cell.width! * Hexagon.heightPerWidth) < 1e-9)
    }

    @Test
    func spiralOffersTheSeedThatFitsItsSpace() {
        let offered = ProposedViewSize(width: 640, height: 480)
        for layout in [SpiralLayout(), SpiralLayout(spacing: 40)] {
            let seed = layout.seedProposal(count: 4, offered: offered)
            let size = layout.arrangement(of: filled(seed, count: 4)).size
            #expect(abs(size.height - 480) < 1e-9)
            #expect(size.width <= 640)
        }
    }

    @Test
    func circularOffersWhatFitsBetweenNeighboursAndInItsSpace() {
        let offered = ProposedViewSize(width: 300, height: 300)
        // Room round a 100 circle: 100 across; 4 neighbours on it are
        // 2·100·sin(45°) ≈ 141 apart, and squares clear along the diagonal
        // at 141/√2 = 100.
        #expect(CircularLayout(radius: 100).itemProposal(count: 4, offered: offered).width == 100)
        let crowded = CircularLayout(radius: 100).itemProposal(count: 12, offered: offered).width!
        #expect(abs(crowded - 200 * sin(Double.pi / 12) / 2.0.squareRoot()) < 1e-9)
    }

    @Test
    func fittedCircleFillsItsSpaceWithoutOverlapping() {
        let offered = ProposedViewSize(width: 640, height: 440)
        for count in 2...12 {
            // However it is turned.
            for degrees in stride(from: -90.0, to: 90, by: 15) {
                let layout = CircularLayout(startAngle: .degrees(degrees))
                let item = layout.itemProposal(count: count, offered: offered)
                let result = layout.arrangement(of: filled(item, count: count), in: offered)
                #expect(abs(result.size.height - 440) < 1e-9, "\(count) at \(degrees)°")
                #expect(result.size.width <= 640)
                #expect(!overlapping(result.frames), "\(count) at \(degrees)°")
            }
        }
    }

    @Test
    func fittedCircleTakesSubviewsOfTheirOwnSizeToItsEdges() {
        let offered = ProposedViewSize(width: 300, height: 300)
        let result = CircularLayout().arrangement(of: Array(repeating: Size(width: 40, height: 40), count: 4), in: offered)
        #expect(result.size == Size(width: 300, height: 300))
        // Top, right, bottom, left, each touching that edge.
        #expect(abs(result.frames[0].minY) < 1e-9)
        #expect(abs(result.frames[1].maxX - 300) < 1e-9)
        #expect(abs(result.frames[2].maxY - 300) < 1e-9)
        #expect(abs(result.frames[3].minX) < 1e-9)
    }

    @Test
    func fittedCircleOfferedNothingIsTheSmallestWithoutOverlaps() {
        let side = 20.0
        let result = CircularLayout().arrangement(of: Array(repeating: Size(width: side, height: side), count: 8), in: .unspecified)
        let radius = side / (2.0.squareRoot() * sin(Double.pi / 8))
        #expect(abs(result.size.width - (radius * 2 + side)) < 1e-9)
        #expect(!overlapping(result.frames))
    }

    @Test
    func fittedCircleOfOneTakesTheWholeSpace() {
        let offered = ProposedViewSize(width: 300, height: 200)
        let layout = CircularLayout()
        let item = layout.itemProposal(count: 1, offered: offered)
        #expect(item == ProposedViewSize(width: 200, height: 200))
        let result = layout.arrangement(of: filled(item, count: 1), in: offered)
        #expect(result.frames == [Rect(x: 0, y: 0, width: 200, height: 200)])
    }

    @Test
    func fixedRadiusKeepsItsSizeWhateverItIsOffered() {
        let sizes = Array(repeating: square, count: 4)
        let small = CircularLayout(radius: 50).arrangement(of: sizes, in: ProposedViewSize(width: 100, height: 100))
        let large = CircularLayout(radius: 50).arrangement(of: sizes, in: ProposedViewSize(width: 900, height: 900))
        #expect(small.size == Size(width: 110, height: 110))
        #expect(large.size == small.size)
    }

    @Test
    func offeredNothingTheyAskSubviewsForTheirOwnSize() {
        #expect(CircularLayout(radius: 50).itemProposal(count: 3, offered: .unspecified) == .unspecified)
        #expect(HoneycombLayout().cellProposal(count: 3, offered: .unspecified) == .unspecified)
        #expect(SpiralLayout().seedProposal(count: 3, offered: .unspecified) == .unspecified)
    }

    @Test
    func spiralStaysInsideItsSquare() {
        let result = SpiralLayout(spacing: 12).arrangement(of: Array(repeating: square, count: 60))
        #expect(result.size.width == result.size.height)
        for frame in result.frames {
            #expect(frame.minX >= -1e-9 && frame.minY >= -1e-9)
            #expect(frame.maxX <= result.size.width + 1e-9 && frame.maxY <= result.size.height + 1e-9)
        }
    }
}
