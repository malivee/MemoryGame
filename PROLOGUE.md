# Keping Kenangan — playable prologue prototype

## Running

Open `MemoryGame.xcodeproj`, choose the MemoryGame scheme and an iPhone/iPad
simulator, then Run. Deployment target: iOS 17+, landscape. No dependencies or
server. The existing supplied village photo is retained as the source image.

The game opens directly on three loose jigsaw fragments on a 6-row × 8-column board. Progress autosaves locally.
“Mulai ulang” asks for confirmation before resetting this prototype's progress.

## Controls

- Drag any earned fragment into any board slot, regardless of its image, edges,
  or rotation. A displaced fragment returns to inventory. Transparent margins
  and holes do not capture taps. Out-of-board drops return the piece to inventory.
- Inventory pages hold ten fragments; use ‹ / › to browse the available pieces.
- Tap to select, then “Putar 90°”. Rotation keeps installed pieces on the board.
  “Simpan” returns the selected fragment to the inventory.
- During exploration, side-adjacent occupied cells count as connected even when
  their physical tabs or image content do not match. Final completion still
  requires the original photo in its correct positions and rotations.
- Tapping a fragment only selects it, even on repeated taps. Enter exclusively
  through “Masuk”. That button stays dimmed/locked until the selected fragment
  belongs to a component of at least three pieces connected along their sides.
  Diagonal contact and pieces in the inventory do not count. Separate groups of
  three or more can be visited independently; the entire photo need not connect.
  The selection label shows connection progress. Breaking a group re-locks it.
- In exploration, use the stick or tap walkable ground. Approach a book, friend,
  or marker and press “Interaksi”. Tap through each dialogue line.
- Return to the photo only after suspicion has cleared. Mission rewards enter
  the inventory; installing them is the separate action that reveals the area.

## Play loop

1. Connect the three starter fragments, select the house fragment and press Masuk.
   Use furniture as cover, then read the old book.
2. Install village areas and finish each friend's conversation, in any order.
3. Install foothill pieces and investigate the road marker. Rotating road pieces
   changes both their visible paths/obstacles and movement/sight collision.
4. Install the boundary. Wait with the three following friends at the meeting
   circle, then bring all four children to the exit. Followers continue moving
   while Arthur waits, using collision-aware paths.
5. Install the closing fragments and arrange all 48 original jigsaw pieces with their
   original orientation. Only then does the seamless photo fade in with
   “Kenangan tersusun”. The dry lake can stay in the inventory.

The dry-lake alternate has the same jigsaw outline as one original lake fragment.
Installing it returns all installed wet-lake fragments to inventory; installing
any wet-lake fragment returns the alternate. Only one lake state is active. Water blocks the basin; dry ground opens a
shortcut. Neither state is labeled as an error. The 48 main pieces form the
original photo; no complete preview, ghost solution, or solve button is exposed.

## Implementation boundaries

This is a prototype with geometric top-down characters and scenery, three compact
reused areas, and 48 interlocking jigsaw fragments plus one dry-lake alternate. Photo travel, memory fog, and the book
remain distinct mechanics. The book is an ordinary story item. No new historical
facts, supernatural explanation for fog/decoys, boss fight, or Hollow attack inside
the village is added. The optional supernatural foreshadowing is not implemented.

All story progression lives in `Models/PrologueProgress.swift`; region definitions
and dialogue are separate. Catches reset positions at a safe checkpoint, preserving
the book, completed conversations, discovered pieces, and mission progress.
Patrol rays and detection use the same obstacle/fog geometry as navigation. NPCs
protect and redirect Arthur rather than physically attacking him.

## Validation

`Validation/main.swift` exercises actual model, level and navigation code on macOS:

```sh
xcrun swiftc MemoryGame/Models/PrologueProgress.swift \
  MemoryGame/Models/PrologueLevel.swift \
  MemoryGame/Models/PuzzlePieceData.swift \
  MemoryGame/Models/JigsawProgress.swift \
  MemoryGame/Models/JigsawOutline.swift \
  MemoryGame/Systems/MemoryNavigation.swift Validation/main.swift \
  -o /tmp/memory-prologue-checks
/tmp/memory-prologue-checks
```

Checks cover reward idempotence, discovery versus installation, free placement,
rotation, lake replacement, conversations, all-four exit gating, final assembly,
save round trips, NPC reachability in every road rotation, group exit paths,
collision, fog, and occluded sight. Simulator build also checked without signing.

Manual device pass still needed: drag accuracy, touch controls on smaller iPhones,
patrol timing, pause/resume, and end-to-end visual/gameplay polish.

## Scenery and memory entry

Selecting a fragment in a ready connected group and pressing Masuk lifts and enlarges that fragment, then fades
into the exploration scene. The location settles into view before controls and
patrols resume. With Reduce Motion enabled, entry uses a short fade instead of a
zoom and ambient drifting particles are disabled. Only the selected tile is shown
during entry, never a complete solution preview.

`SceneryPainter` draws deterministic top-down terrain inspired by the supplied
photo: warm plaster cottages with terracotta tiles, olive grass and wildflowers,
dirt paths, mossy stone, teal water, and timber furniture indoors. Four recently
used scenery textures are cached. The painted houses, trees and rocks share the
level's collision/visibility footprints. Surface grass and flowers are walkable.
Water ripples and drifting leaves/dust are separate animated layers; unrevealed
zones remain covered by opaque memory fog.

## 48-piece progress and upgrade

Nine story locations are mapped to groups of physical fragments. A new game
starts with three fragments (house, yard and road) that can form an L-shaped
connected group. Mission packs gradually provide more fragments: 3 initially,
15 after reading the book, 27 after the three conversations, 39 after the marker,
and 49 after leaving together (48 originals plus the dry-lake alternate).

A location is available only if one of its fragments belongs to a connected group
of at least three. Photo entry and exploration fog use this same condition. The
last manipulated eligible fragment controls its location's rotation in exploration.
The
final photo requires all 48 originals in their own cells, unrotated, plus the
completed exit mission. Inventory sorting is shuffled and contains no row/column
solution labels. The photo-entry animation and painted scenery remain active.

Existing nine-tile saves migrate once: story flags and rewards survive, and each
previously installed location becomes a compatible representative jigsaw piece;
it still needs a connected group before it can be visited.
An already completed prologue receives the complete 48-piece arrangement. New
48-piece arrangements are saved alongside the same story progress.

Geometry validation samples the actual Bezier paths across the full photograph
to detect gaps/overlaps and validates physical fit, alternate replacement, story
unlocks, final assembly, save reloads and migration from saves without jigsaw data.

## Connectivity-rule migration

Old pre-book saves exchange the two disconnected starter shapes for the new
connectable starter set; pieces whose shapes no longer fit their former cells
return to inventory. Story flags are retained. Later saves retain fragments they
already earned under earlier reward rules; new games use the smaller mission
packs above. Use the existing confirmed “Mulai ulang” action to try the opening
from scratch. No saved game is automatically reset.

Validation covers one/two/three-piece gates, diagonal exclusion, row-boundary
wrapping, bridge removal, independent components, world fog synchronization,
solvability of the opening and every reward pack, and save migration/reload.
