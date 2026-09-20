#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."
build_dir=$(mktemp -d /tmp/memorygame-architecture.XXXXXX)
trap 'rm -rf "$build_dir"' EXIT
swiftc -module-cache-path "$build_dir/modules" \
  MemoryGame/Models/PrologueProgress.swift \
  MemoryGame/Models/JigsawProgress.swift \
  MemoryGame/Models/PuzzleWorld.swift \
  MemoryGame/Models/PuzzlePieceData.swift \
  MemoryGame/Models/EchoesBoundaryLevel.swift \
  MemoryGame/Models/BoundaryLevel.swift \
  MemoryGame/Models/Boundary/RockSaltMineLevel.swift \
  MemoryGame/Models/Boundary/HerbalHillsLevel.swift \
  MemoryGame/Models/Boundary/WoodcutterSlopeLevel.swift \
  MemoryGame/Models/Boundary/TheBoundaryLevel.swift \
  MemoryGame/Models/PrologueLevel.swift \
  MemoryGame/Systems/PuzzleSession.swift \
  MemoryGame/Systems/ExplorationCollisionGeometry.swift \
  Validation/Architecture/main.swift \
  -o "$build_dir/checks"
"$build_dir/checks"
