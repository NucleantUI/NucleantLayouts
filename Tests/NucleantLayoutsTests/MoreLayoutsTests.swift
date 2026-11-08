import Foundation
import NucleantUI
import Testing
@testable import NucleantLayouts

/// Wave, arc, rings, cascade, treemap, justified, bento, equal width,
/// carousel and pyramid: each one's arrangement checked against positions
/// worked out by hand, and its proposals against the space it is offered.
@MainActor
@Suite
struct MoreArrangements {
    let square = Size(width: 10, height: 10)

    // MARK: Wave

    @Test
    func waveLiftsEachSubviewAlongTheSine() {
        let result = WaveLayout(amplitude: 10, waves: 1).arrangement(of: Array(repeating: square, count: 4), gap: 0)
        #expect(result.size == Size(width: 40, height: 30))
        // Centres an eighth, three eighths, … of the way along: up, up,
        // down, down by 10·sin(45°).
        let lift = 10 * sin(Double.pi / 4)
        let expected = [15 - lift, 15 - lift, 15 + lift, 15 + lift]
        for (frame, y) in zip(result.frames, expected) {
            #expect(close(frame.midY, y))
        }
        #expect(result.frames.map(\.minX) == [0, 10, 20, 30])
    }

    @Test
    func wavePhaseShiftsTheWave() {
        // A quarter turn on: the first subview, at the very start, is at a
        // crest.
        let result = WaveLayout(amplitude: 10, waves: 1, phase: .degrees(90))
            .arrangement(of: [Size(width: 0, height: 10), square], gap: 0)
        #expect(close(result.frames[0].midY, 15 - 10))
    }

    @Test
    func waveOffersAnEvenShareBelowItsSwing() {
        let layout = WaveLayout(amplitude: 30)
        #expect(layout.itemProposal(count: 4, offered: ProposedViewSize(width: 100, height: 300), gap: 4).width == 22)
        #expect(layout.itemProposal(count: 4, offered: ProposedViewSize(width: 400, height: 80), gap: 4).width == 20)
        #expect(layout.itemProposal(count: 4, offered: .unspecified, gap: 4) == .unspecified)
    }

    // MARK: Arc

    @Test
    func arcRunsFromItsStartToItsEnd() {
        let arc = ArcLayout(radius: 100, startAngle: .degrees(-180), endAngle: .degrees(0))
        let result = arc.arrangement(of: Array(repeating: square, count: 3), in: .unspecified)
        // Left, top, right of the circle; the box is round the subviews only.
        #expect(close(result.size.width, 210) && close(result.size.height, 110))
        #expect(close(result.frames[0].center.x, 5) && close(result.frames[0].center.y, 105))
        #expect(close(result.frames[1].center.x, 105) && close(result.frames[1].center.y, 5))
        #expect(close(result.frames[2].center.x, 205) && close(result.frames[2].center.y, 105))
        #expect(close(arc.angle(ofSubviewAt: 1, count: 3).degrees, -90))
    }

    @Test
    func arcOfAWholeTurnDoesNotLandTheLastOnTheFirst() {
        let arc = ArcLayout(radius: 50, startAngle: .degrees(-90), endAngle: .degrees(270))
        let angles = (0..<4).map { arc.angle(ofSubviewAt: $0, count: 4).degrees }
        #expect(zip(angles, [-90.0, 0, 90, 180]).allSatisfy { close($0, $1) })
    }

    @Test
    func fittedArcFillsItsSpaceWithoutOverlapping() {
        let offered = ProposedViewSize(width: 640, height: 300)
        for count in 2...16 {
            for span in [60.0, 140, 220, 330, 360] {
                let arc = ArcLayout(startAngle: .degrees(-90 - span / 2), endAngle: .degrees(-90 + span / 2))
                let item = arc.itemProposal(count: count, offered: offered)
                let result = arc.arrangement(of: filled(item, count: count), in: offered)
                #expect(result.size.width <= 640 + 1e-6 && result.size.height <= 300 + 1e-6, "\(count) over \(span)°")
                #expect(close(result.size.width, 640, within: 1e-6) || close(result.size.height, 300, within: 1e-6))
                #expect(!overlapping(result.frames), "\(count) over \(span)°")
            }
        }
    }

    // MARK: Rings

    @Test
    func ringsHoldSixMoreEachTime() {
        #expect(RingsLayout.rings(for: 1) == 0)
        #expect(RingsLayout.rings(for: 7) == 1)
        #expect(RingsLayout.rings(for: 8) == 2)
        #expect(RingsLayout.rings(for: 19) == 2)
        #expect(RingsLayout.rings(for: 20) == 3)
    }

    @Test
    func ringsPutTheFirstInTheMiddleAndTheNextAtTheTop() {
        let result = RingsLayout(spacing: 0).arrangement(of: Array(repeating: square, count: 7), gap: 0)
        let step = 2.0.squareRoot() * 10
        #expect(close(result.size.width, 2 * step + 10))
        let middle = result.size.width / 2
        #expect(close(result.frames[0].center.x, middle) && close(result.frames[0].center.y, middle))
        #expect(close(result.frames[1].center.x, middle) && close(result.frames[1].center.y, middle - step))
    }

    @Test
    func ringsNeverOverlapHoweverTwisted() {
        for twist in stride(from: 0.0, to: 180, by: 17) {
            let result = RingsLayout(twist: .degrees(twist)).arrangement(of: Array(repeating: square, count: 40), gap: 0)
            #expect(!overlapping(result.frames), "twisted \(twist)°")
        }
    }

    @Test
    func ringsOfferTheSquareThatFitsTheirSpace() {
        let layout = RingsLayout(spacing: 6)
        let offered = ProposedViewSize(width: 500, height: 420)
        for count in [1, 7, 24, 40] {
            let item = layout.itemProposal(count: count, offered: offered, gap: 6)
            let size = layout.arrangement(of: filled(item, count: count), gap: 6).size
            #expect(close(size.height, 420, within: 1e-6), "\(count)")
        }
    }

    // MARK: Cascade

    @Test
    func cascadeMovesEachFromTheOneBefore() {
        let card = Size(width: 100, height: 50)
        let result = CascadeLayout(horizontalOffset: 24, verticalOffset: 18).arrangement(of: Array(repeating: card, count: 3))
        #expect(result.frames.map(\.origin) == [Point(x: 0, y: 0), Point(x: 24, y: 18), Point(x: 48, y: 36)])
        #expect(result.size == Size(width: 148, height: 86))
    }

    @Test
    func cascadeWithNegativeOffsetsGoesTheOtherWay() {
        let result = CascadeLayout(horizontalOffset: -10, verticalOffset: 0).arrangement(of: Array(repeating: square, count: 3))
        #expect(result.frames.map(\.origin) == [Point(x: 20, y: 0), Point(x: 10, y: 0), Point(x: 0, y: 0)])
        #expect(result.size == Size(width: 30, height: 10))
    }

    @Test
    func cascadeOffersWhatTheOffsetsLeave() {
        let item = CascadeLayout(horizontalOffset: 24, verticalOffset: 10)
            .itemProposal(count: 3, offered: ProposedViewSize(width: 300, height: nil))
        #expect(item == ProposedViewSize(width: 252, height: nil))
    }

    // MARK: Treemap

    @Test
    func treemapStartsWithTheSquarifiedColumn() {
        // Bruls, Huizing and van Wijk's own example, scaled up a hundred.
        let weights = [6.0, 6, 4, 3, 2, 2, 1]
        let cells = TreemapLayout(spacing: 0).arrangement(weights: weights, in: Size(width: 600, height: 400), gap: 0)
        #expect(close(cells[0], Rect(x: 0, y: 0, width: 300, height: 200), within: 1e-6))
        #expect(close(cells[1], Rect(x: 0, y: 200, width: 300, height: 200), within: 1e-6))
    }

    @Test
    func treemapCellsCoverTheBoxInProportion() {
        let weights = [5.0, 1, 3, 0.5, 2, 2, 8, 1, 4]
        let box = Size(width: 640, height: 360)
        let cells = TreemapLayout().arrangement(weights: weights, in: box, gap: 0)
        let total = weights.reduce(0, +)
        for (cell, weight) in zip(cells, weights) {
            #expect(close(cell.width * cell.height, box.width * box.height * weight / total, within: 1e-6))
            #expect(cell.minX >= -1e-9 && cell.minY >= -1e-9)
            #expect(cell.maxX <= box.width + 1e-6 && cell.maxY <= box.height + 1e-6)
        }
        #expect(!overlapping(cells))
    }

    @Test
    func treemapLeavesAGapBetweenCellsAndNoneAtTheEdges() {
        let cells = TreemapLayout().arrangement(weights: [1, 1], in: Size(width: 210, height: 100), gap: 10)
        #expect(close(cells[0], Rect(x: 0, y: 0, width: 100, height: 100)))
        #expect(close(cells[1], Rect(x: 110, y: 0, width: 100, height: 100)))
    }

    @Test
    func treemapOfNoWeightSharesEvenly() {
        let cells = TreemapLayout().arrangement(weights: [0, 0], in: Size(width: 200, height: 100), gap: 0)
        #expect(close(cells[0].width * cells[0].height, 10_000))
        #expect(close(cells[1].width * cells[1].height, 10_000))
    }

    // MARK: Justified

    @Test
    func justifiedRowsFillTheWidthAndTheLastKeepsItsHeight() {
        let result = JustifiedLayout(rowHeight: 100).arrangement(of: [1, 1, 1, 1, 1], width: 300, gaps: .zero)
        #expect(result.frames[0..<3].allSatisfy { close($0.height, 100) && close($0.width, 100) && $0.minY == 0 })
        #expect(close(result.frames[2].maxX, 300))
        // Two left over: not stretched to the width.
        #expect(result.frames[3] == Rect(x: 0, y: 100, width: 100, height: 100))
        #expect(result.frames[4] == Rect(x: 100, y: 100, width: 100, height: 100))
        #expect(result.size == Size(width: 300, height: 200))
    }

    @Test
    func justifiedEndsARowWhereItsHeightIsNearestTheAim() {
        // Two fill 400 at 133, three at 89: three is nearer 100.
        let result = JustifiedLayout(rowHeight: 100).arrangement(of: [1.5, 1.5, 1.5], width: 400, gaps: .zero)
        #expect(result.frames.allSatisfy { close($0.height, 400 / 4.5) && $0.minY == 0 })
        #expect(close(result.frames[2].maxX, 400))
    }

    @Test
    func justifiedKeepsGapsBetweenCellsAndRows() {
        let result = JustifiedLayout(rowHeight: 100).arrangement(of: [1, 1, 1], width: 210, gaps: Size(width: 10, height: 6))
        #expect(close(result.frames[0], Rect(x: 0, y: 0, width: 100, height: 100)))
        #expect(close(result.frames[1], Rect(x: 110, y: 0, width: 100, height: 100)))
        #expect(close(result.frames[2], Rect(x: 0, y: 106, width: 100, height: 100)))
    }

    @Test
    func justifiedWithNoWidthIsOneRow() {
        let result = JustifiedLayout(rowHeight: 50).arrangement(of: [1, 2], width: nil, gaps: .zero)
        #expect(result.frames == [Rect(x: 0, y: 0, width: 50, height: 50), Rect(x: 50, y: 0, width: 100, height: 50)])
        #expect(result.size == Size(width: 150, height: 50))
    }

    // MARK: Bento

    @Test
    func bentoPlacesEachSpanInTheFirstPlaceItFits() {
        let spans = [
            BentoSpan(columns: 2, rows: 2), BentoSpan(columns: 1, rows: 1), BentoSpan(columns: 1, rows: 1),
            BentoSpan(columns: 2, rows: 1), BentoSpan(columns: 1, rows: 1),
        ]
        let places = BentoLayout(columns: 3).placements(of: spans)
        #expect(places.map { $0.column } == [0, 2, 2, 0, 2])
        #expect(places.map { $0.row } == [0, 0, 1, 2, 2])
    }

    @Test
    func bentoFillsAGapLeftEarlier() {
        // The second wide one doesn't fit beside the first, so it drops a
        // row; the small one after it takes the cell it left.
        let spans = [BentoSpan(columns: 2, rows: 1), BentoSpan(columns: 2, rows: 1), BentoSpan(columns: 1, rows: 1)]
        let places = BentoLayout(columns: 3).placements(of: spans)
        #expect(places.map { $0.column } == [0, 0, 2])
        #expect(places.map { $0.row } == [0, 1, 0])
    }

    @Test
    func bentoSpansCoverTheirCellsAndTheGapsBetween() {
        let spans = [BentoSpan(columns: 2, rows: 2), BentoSpan(columns: 5, rows: 1)]
        let result = BentoLayout(columns: 3).arrangement(of: spans, cell: Size(width: 100, height: 100), gaps: Size(width: 10, height: 10))
        #expect(result.frames[0] == Rect(x: 0, y: 0, width: 210, height: 210))
        // Wider than the grid: cut to its three columns.
        #expect(result.frames[1] == Rect(x: 0, y: 220, width: 320, height: 100))
        #expect(result.size == Size(width: 320, height: 320))
    }

    // MARK: Equal width

    @Test
    func equalWidthGivesEveryCellTheSameWidth() {
        let result = EqualWidthHStack().arrangement(
            of: [Size(width: 50, height: 20), Size(width: 50, height: 40)],
            cellWidth: 50,
            gaps: [10]
        )
        #expect(result.frames == [Rect(x: 0, y: 10, width: 50, height: 20), Rect(x: 60, y: 0, width: 50, height: 40)])
        #expect(result.size == Size(width: 110, height: 40))
    }

    @Test
    func equalWidthAlignsShorterCells() {
        let sizes = [Size(width: 50, height: 20), Size(width: 50, height: 40)]
        let top = EqualWidthHStack(alignment: .top).arrangement(of: sizes, cellWidth: 50, gaps: [0])
        let bottom = EqualWidthHStack(alignment: .bottom).arrangement(of: sizes, cellWidth: 50, gaps: [0])
        #expect(top.frames[0].minY == 0)
        #expect(bottom.frames[0].minY == 20)
    }

    // MARK: Carousel

    @Test
    func carouselShrinksEachStepAway() {
        let layout = CarouselLayout(selection: 2, falloff: 0.5)
        #expect(layout.scale(of: 2) == 1)
        #expect(layout.scale(of: 3) == 0.5)
        #expect(layout.scale(of: 0) == 0.25)
    }

    @Test
    func carouselCentresTheSelection() {
        let sizes = [10.0, 20, 40, 20, 10].map { Size(width: $0, height: $0) }
        var layout = CarouselLayout(selection: 2, spacing: 0)
        let settled = layout.arrangement(of: sizes, width: 200)
        #expect(settled.frames[2].midX == 100)
        #expect(settled.frames[2].minY == 0 && settled.frames[0].minY == 15)
        #expect(settled.size == Size(width: 200, height: 40))
        // Halfway to the next: the point between the two is in the middle.
        layout.selection = 2.5
        let moving = layout.arrangement(of: sizes, width: 200)
        #expect(close((moving.frames[2].midX + moving.frames[3].midX) / 2, 100))
    }

    @Test
    func carouselSelectionIsAsTallAsItsSpaceAndNoWiderThanHalf() {
        let layout = CarouselLayout()
        #expect(layout.selectedSide(offered: ProposedViewSize(width: 800, height: 300)) == 300)
        #expect(layout.selectedSide(offered: ProposedViewSize(width: 400, height: 300)) == 200)
        #expect(layout.selectedSide(offered: .unspecified) == nil)
    }

    // MARK: Pyramid

    @Test
    func pyramidRowsGrowByOne() {
        #expect(PyramidLayout.rows(for: 6) == [1, 2, 3])
        #expect(PyramidLayout.rows(for: 8) == [1, 2, 3, 2])
    }

    @Test
    func pyramidCentresEachRow() {
        let result = PyramidLayout().arrangement(of: Array(repeating: square, count: 4), gap: 0)
        #expect(result.frames.map(\.origin) == [Point(x: 5, y: 0), Point(x: 0, y: 10), Point(x: 10, y: 10), Point(x: 5, y: 20)])
        #expect(result.size == Size(width: 20, height: 30))
    }

    @Test
    func invertedPyramidStandsOnItsPoint() {
        let result = PyramidLayout(inverted: true).arrangement(of: Array(repeating: square, count: 3), gap: 0)
        #expect(result.frames.map(\.origin) == [Point(x: 5, y: 10), Point(x: 0, y: 0), Point(x: 10, y: 0)])
    }

    @Test
    func pyramidOffersTheSquareThatFitsItsSpace() {
        let item = PyramidLayout().itemProposal(count: 6, offered: ProposedViewSize(width: 300, height: 600), gap: 0)
        #expect(item == ProposedViewSize(width: 100, height: 100))
    }
}
