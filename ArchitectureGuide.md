# Architecture Guide

Use this structure for new files in this project:

- `App/`: app lifecycle and view-controller entry points.
- `Scenes/`: SpriteKit scenes, grouped by screen or gameplay mode.
- `Models/`: plain data types and game state.
- `Entities/`: SpriteKit node subclasses or entity factory code grouped by domain.
- `Systems/`: logic that operates on ECS components or gameplay collections.
- `Services/`: platform or persistence services such as audio, saves, and haptics.
- `Resources/`: assets, SpriteKit scene files, sounds, and level data.
- `Shared/`: constants, physics categories, ECS primitives, and small extensions.

For new classes or structs, choose the folder by responsibility before creating the file. Keep ECS components as small data structs, systems as stateless logic where possible, and SpriteKit rendering details in scenes or entity node types.

## Current boundaries

The active game uses domain models and SpriteKit scene adapters. The older ECS
scaffolding is optional infrastructure, not the architecture of the current puzzle.

- `Models/JigsawProgress.swift` owns connectivity, unlocked destinations, and board state.
- `Systems/PuzzleSession.swift` is the shared command boundary for all three puzzle
  layouts. Placement rejects occupied cells without evicting either piece; rotation
  and removal do not depend on SpriteKit or persistence.
- `Models/PrologueProgress.swift` owns story progression. `Services/PrologueStore.swift`
  alone handles its UserDefaults encoding, loading, and reset. The save key and
  Codable representation are unchanged.
- `Systems/ExplorationCollisionGeometry.swift` owns ground collision footprints.
  Scene rendering and navigation consume the same level data.
- `Services/JournalPaginator.swift` computes journal page breaks with UIKit text
  measurement. `Models/JournalPage.swift` describes the result, and
  `Scenes/Books/JournalPageArtwork.swift` renders textures from that plan.

## Scene file convention

Each main scene file declares its shared state and lifecycle wiring. Companion
files separate responsibilities:

- `+Rendering.swift`: node construction, layout, labels, highlights, and visual effects.
- `+Input.swift`: touches, gesture recognition, hit testing, and conversion into commands.
- `+Flow.swift`: saving and transitions between screens.
- `+Gameplay.swift`: exploration update and interaction orchestration.
- `+PageTurning.swift`: book animation timing and turn completion.

These extensions are adapters on the same SpriteKit scene, not independent view
models. They may coordinate animations and invoke rendering methods; game rules
that can run without a scene belong in Models or Systems. Internal access on shared
scene members supports cross-file extensions and is not a public API. Do not add
node construction to input handlers or duplicate domain rules between layouts.
Keep all three puzzle variants; their layout differences are intentional.

## Verification

Run `sh Validation/Architecture/run.sh` for standalone domain regressions covering
placement, occupied cells, rotation, portals, rewards, save decoding, and collision
geometry. These checks require neither SpriteKit nor a running simulator.

Build the iOS target after moving scene methods; Swift access control and selector
wiring cross file boundaries. Gesture feel, animations, and visual layout still
need an interactive simulator/device check. The older `Validation/main.swift`
contains historical board assumptions and is not the current architecture suite.
