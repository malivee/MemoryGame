import Foundation
import CoreGraphics

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError(message) }
}

check(VillageCartoBlankMap.subdivisions == 6, "Each source cell must expose a 6 x 6 grid")
check(VillageCartoBlankMap.subcellSide == VillageCartoBlankMap.side / 6, "Subcell size must divide cleanly")
check(VillageCartoBlankMap.pieces.count == 45, "Blank map retains every Carto tetromino")

var covered: Set<VillageCartoBlankMap.Cell> = []
for piece in VillageCartoBlankMap.pieces {
    check(piece.count == 4, "Each piece must have exactly four cells")
    check(Set(piece).count == 4, "Piece cells must not overlap")
    check(covered.isDisjoint(with: Set(piece)), "Pieces must not overlap")
    covered.formUnion(piece)
}
check(covered.count == VillageCartoBlankMap.columns * VillageCartoBlankMap.rows, "Source grid has no gaps")
check(VillageCartoBlankMap.subcellRect(column: 0, row: 0)?.size
    == CGSize(width: 16, height: 16), "Blank grid uses 16-point slots")
check(VillageCartoBlankMap.subcellRect(column: 107, row: 59)?.maxX == 1728, "Last 6 x 6 slot is valid")
check(VillageCartoBlankMap.subcellRect(column: 108, row: 0) == nil, "Out-of-bounds slot rejected")
check(VillageCartoBlankMap.blankBackgroundColor.alpha == 1, "Blank background is a solid color")
print("PASS: blank Carto map has 45 tetrominoes and a 6 x 6 grid per cell")
