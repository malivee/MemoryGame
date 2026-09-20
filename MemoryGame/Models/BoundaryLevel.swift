import CoreGraphics
import Foundation

/// Router level untuk Map B (Pinggiran / Zona Transisi)
/// Mendelegasikan konfigurasi level ke sub-tahap yang sesuai berdasarkan `progress.mapBStage`:
/// - Tahap 1: `RockSaltMineLevel` (Panel 4)
/// - Tahap 2: `HerbalHillsLevel` (Panel 5)
/// - Tahap 3: `WoodcutterSlopeLevel` (Panel 6)
/// - Tahap 4: `TheBoundaryLevel` (Panel 7)
enum BoundaryLevel {
    static func make(region: MemoryRegion, progress: PrologueProgress) -> PrologueLevel {
        switch progress.mapBStage {
        case .rockSalt:
            return RockSaltMineLevel.make(region: region, progress: progress)
        case .herbalHills:
            return HerbalHillsLevel.make(region: region, progress: progress)
        case .woodcutterSlope:
            return WoodcutterSlopeLevel.make(region: region, progress: progress)
        case .theBoundary:
            return TheBoundaryLevel.make(region: region, progress: progress)
        }
    }
}
