You are continuing development of a 2D puzzle-adventure game for iOS using Swift and SpriteKit.

The project already has or is currently implementing:

- tetromino-based world pieces;
- WorldState;
- Map View and World View;
- realtime tetromino dragging;
- realtime tetromino rotation;
- pannable Map View;
- a 6×6 authoritative Micro Biome Grid inside every large grid cell;
- biome rotation together with its owning tetromino.

The current task is NOT to implement building placement yet.

The current task is to replace generic/random graybox biome data with the **first deliberately designed 5-piece biome puzzle fixture**.

The purpose is to prove that reshuffling and rotating tetrominoes can create or destroy sufficiently large continuous areas of `Village Soil`.

This will become the spatial foundation for future building-placement quests.

---

# 1. GAMEPLAY DIRECTION

The main gameplay objective is no longer:

```text
Find an exit
```

The intended loop is:

```text
Quest introduces spatial requirements
↓
Player reshuffles tetromino pieces
↓
Village Soil fragments connect differently
↓
Player creates sufficient buildable surface
↓
Player places required buildings
↓
Quest conditions are satisfied
```

Building placement itself comes in a later phase.

For now, we need terrain data capable of supporting this gameplay.

---

# 2. IMPORTANT TERRAIN RULE

Buildings will eventually be placeable ONLY on:

```text
Village Soil
```

They cannot stand on:

```text
Natural Grass
```

For the three confirmed core pieces in this fixture:

```text
Z1
Z2
L1
```

only these two biomes are used:

```swift
.villageSoil
.naturalGrass
```

For this prototype, also use only Village Soil and Natural Grass on the remaining two pieces.

Do not introduce:

- Rocksalt;
- Dark Green Forest;
- Hill Soil

into this fixture yet.

Those biomes remain valid game biome types, but this particular prototype should isolate the buildable-land mechanic.

---

# 3. AUTHORITATIVE RESOLUTION

One large grid cell contains:

```text
6 × 6 micro cells
```

The 6×6 microgrid remains the authoritative gameplay terrain resolution.

Do NOT introduce a second simulation grid.

World View may group terrain differently visually, but all terrain and future building validation must come from the same 6×6 data.

---

# 4. FIVE PIECES

Use exactly five tetromino pieces for this fixture:

```text
Z1
Z2
L1
T1
S1
```

Shapes:

## Z1

```text
    [A][B]
 [C][D]
```

## Z2

```text
    [E][F]
 [G][H]
```

## L1

```text
[I]
[J]
[K][L]
```

## T1

```text
[M][N][O]
   [P]
```

## S1

```text
   [Q][R]
[S][T]
```

Each letter represents one large grid cell.

Every large grid cell contains its own 6×6 MicroBiomeGrid.

---

# 5. DESIGN PRINCIPLE

Do NOT make most large cells homogeneous.

The majority of the 20 large cells should contain both:

```text
Village Soil
+
Natural Grass
```

The point is that Village Soil exists as spatial fragments.

The player must reshape the world so those fragments create sufficiently large continuous buildable areas.

Desired mental model:

```text
Village fragment
+
Village fragment
+
rotation
+
piece adjacency
=
large buildable footprint
```

Avoid a design where the player simply looks for one giant Village Soil cell.

---

# 6. SYMBOLS

For debug matrices:

```text
V = Village Soil
G = Natural Grass
```

---

# 7. Z1 BIOME MASKS

Shape:

```text
    [A][B]
 [C][D]
```

## Cell A

```text
V V V V G G
V V V V G G
V V V G G G
V V V G G G
V V G G G G
V G G G G G
```

## Cell B

```text
G G G V V V
G G G V V V
G G G V V V
G G V V V V
G G V V V V
G V V V V V
```

## Cell C

```text
V V V G G G
V V V G G G
V V V G G G
V V V G G G
V V V G G G
V V V G G G
```

## Cell D

```text
G G G V V V
G G G V V V
G G G V V V
G G G V V V
G G G V V V
G G G V V V
```

Z1 is intentionally designed around complementary half-width Village Soil strips.

C and D are especially important for producing a possible 6×6 Village Soil region when their relevant edges are arranged correctly.

---

# 8. Z2 BIOME MASKS

Shape:

```text
    [E][F]
 [G][H]
```

## Cell E

```text
V V V V V V
V V V V V V
V V V V V V
V V V V G G
V V V G G G
V V G G G G
```

## Cell F

```text
G G G G V V
G G G V V V
G G V V V V
V V V V V V
V V V V V V
V V V V V V
```

## Cell G

```text
V V V G G G
V V V G G G
V V G G G G
V V G G G G
V G G G G G
V G G G G G
```

## Cell H

```text
G G V V V V
G G V V V V
G V V V V V
G V V V V V
V V V V V V
V V V V V V
```

Z2 should be useful for creating long Village Soil regions, especially for future 6×9 footprints.

---

# 9. L1 BIOME MASKS

Shape:

```text
[I]
[J]
[K][L]
```

## Cell I

```text
V V V V V G
V V V V V G
V V V V V G
V V V V V G
V V V V V G
G G G G G G
```

## Cell J

```text
V V V V V G
V V V V V G
V V V V V G
V V V V V G
V V V V V G
V V V V V G
```

## Cell K

```text
G G G G G G
G V V V V V
G V V V V V
G V V V V V
G V V V V V
G V V V V V
```

## Cell L

```text
V V V V G G
V V V V G G
V V V V G G
V V V V G G
G G G G G G
G G G G G G
```

L1 should become one of the most valuable pieces for creating large continuous Village Soil footprints.

It should not independently solve the largest future building requirement.

Its usefulness should come from combining its wide Village Soil regions with other pieces.

---

# 10. T1 BIOME MASKS

Shape:

```text
[M][N][O]
   [P]
```

## Cell M

```text
G G G V V V
G G G V V V
G G G V V V
G G G V V V
G G G V V V
G G G V V V
```

## Cell N

```text
V V V V V V
V V V V V V
V V V V V V
G G G G G G
G G G G G G
G G G G G G
```

## Cell O

```text
V V V G G G
V V V G G G
V V V G G G
V V V G G G
V V V G G G
V V V G G G
```

## Cell P

```text
G G G G G G
G G G G G G
V V V V V V
V V V V V V
V V V V V V
V V V V V V
```

T1 is a support piece.

Its main purpose is creating wide horizontal or vertical Village Soil bands depending on rotation.

---

# 11. S1 BIOME MASKS

Shape:

```text
   [Q][R]
[S][T]
```

## Cell Q

```text
V V G G G G
V V V G G G
V V V V G G
V V V V V G
V V V V V V
V V V V V V
```

## Cell R

```text
G G G G V V
G G G V V V
G G V V V V
G V V V V V
V V V V V V
V V V V V V
```

## Cell S

```text
V V V V G G
V V V V G G
V V V V G G
G G G G G G
G G G G G G
G G G G G G
```

## Cell T

```text
G G G G G G
G G G G G G
G G G V V V
G G G V V V
G G G V V V
G G G V V V
```

S1 should behave as a tactical support piece rather than a large standalone buildable block.

---

# 12. FUTURE BUILDING FOOTPRINTS

Do NOT implement these buildings yet.

However, terrain design must be evaluated against these known future footprint sizes:

```text
Well
3 × 3

Arthur's House
6 × 9

Mara's House
6 × 6

Barn
9 × 15
```

All dimensions are measured in authoritative micro-grid cells.

Buildings will only be valid when every footprint micro cell lies on:

```text
Village Soil
```

---

# 13. BUILDINGS MAY CROSS LARGE-CELL BOUNDARIES

This fixture must be designed with the assumption that future buildings may cover terrain such as:

```text
Large Cell A | Large Cell B
             |
V V V        | V V V
V V V        | V V V
```

A future 6×2 or similar footprint could span the seam.

Therefore global micro terrain resolution must already treat adjacent large cells seamlessly.

Do not design future building logic around:

```text
building belongs to exactly one large cell
```

---

# 14. BUILDINGS MAY CROSS TETROMINO BOUNDARIES

Future building placement may also occupy Village Soil generated across:

```text
Piece Z1 | Piece L1
```

The future validator will use:

```text
GlobalMicroPosition
```

not ownership by a single tetromino.

This fixture should actively contain useful Village Soil seams between different pieces.

---

# 15. BUILDING FOOTPRINTS ARE NOT ALLOWED ON GRASS

The later rule will be strict:

```text
every covered micro cell
must equal
.villageSoil
```

Example:

```text
V V V
V V V
```

valid.

Example:

```text
V V V
V V G
```

invalid.

Do not introduce tolerance, percentages, or majority voting.

---

# 16. INITIAL STATE MUST NOT ALREADY SOLVE EVERYTHING

Create an initial arrangement of the five pieces that is intentionally spatially poor.

The starting layout should:

- expose the five pieces clearly;
- allow Map View interaction;
- avoid overlapping pieces;
- contain at least one easy 3×3 Village Soil area;
- NOT contain an obvious 9×15 Village Soil rectangle;
- preferably NOT contain a trivial 6×9 Village Soil rectangle;
- require meaningful reshuffling to create large buildable surfaces.

Do NOT tightly pack all five pieces into an immediately useful Village Soil super-region.

---

# 17. INITIAL WELL OPPORTUNITY

The starting state should contain at least one relatively obvious:

```text
3×3 Village Soil
```

region.

This ensures the smallest future building can be introduced without requiring advanced reshuffling.

---

# 18. 6×6 TARGET

There must exist at least one reachable arrangement of pieces that creates a continuous:

```text
6×6 Village Soil
```

rectangle.

This will later support Mara's House.

The arrangement should ideally use Village Soil from more than one large cell.

---

# 19. 6×9 TARGET

There must exist at least one reachable arrangement that creates:

```text
6×9
```

or:

```text
9×6
```

continuous Village Soil.

This will later support Arthur's House.

Prefer a solution that crosses:

- at least two large cells;
- ideally two tetromino pieces.

---

# 20. 9×15 TARGET

There must exist at least one valid arrangement that creates:

```text
9×15
```

or:

```text
15×9
```

continuous Village Soil.

This will later support the Barn.

The Barn target is expected to require several large cells and preferably at least three tetromino pieces.

Do not require one large cell or one single tetromino to contain the Barn footprint.

---

# 21. SOLVABILITY MUST BE VERIFIED PROGRAMMATICALLY

Do not merely look at the masks and assume they can form the required footprints.

Implement domain-level utilities to inspect rectangular Village Soil availability.

For example:

```swift
func containsVillageSoilRectangle(
    width: Int,
    height: Int,
    in worldState: WorldState
) -> Bool
```

This is NOT yet building placement.

It is a debug/fixture verification tool.

It should scan the resolved global microgrid for a fully contiguous Village Soil rectangle.

---

# 22. SUPPORT ROTATED FOOTPRINTS

The debug footprint search should support:

```text
width × height
```

and:

```text
height × width
```

when appropriate.

For example Arthur:

```text
6×9
OR
9×6
```

Barn:

```text
9×15
OR
15×9
```

The Well and Mara House are square.

---

# 23. DEBUG FOOTPRINT OVERLAY

In DEBUG Map View, add an optional overlay that can highlight a discovered Village Soil rectangle.

Example controls:

```text
SHOW 3×3
SHOW 6×6
SHOW 6×9
SHOW 9×15
```

When a matching region exists:

highlight its micro cells.

This is development tooling only.

Do NOT implement actual buildings.

---

# 24. CURRENT MAX RECTANGLE DEBUG INFO

Add a debug utility capable of reporting something like:

```text
Largest Village Soil Rectangle:
6 × 7

Area:
42 microcells
```

This will help tune puzzle masks.

Exact algorithm is up to implementation.

Performance is not a concern for this tiny prototype.

---

# 25. BIOME AREA COUNTS

Add debug statistics:

```text
Village Soil:
N cells

Natural Grass:
M cells

Total:
720
```

Verify:

```text
N + M == 720
```

for this fixture.

Do not target a specific Village Soil percentage blindly.

Report the actual value first.

---

# 26. DO NOT OPTIMIZE ONLY FOR TOTAL AREA

A map can have enough total Village Soil but still fail to provide a usable rectangle.

Therefore both are important:

```text
total Village Soil amount
```

and:

```text
spatial shape / continuity
```

The 9×15 Barn requirement is primarily a spatial-layout challenge.

---

# 27. ROTATION MUST TRANSFORM BIOME MASKS

When any piece is rotated:

```text
piece geometry rotates
AND
all four 6×6 biome masks rotate
```

The debug footprint scanner must immediately see the new resolved orientation.

Do not manually author separate 0°, 90°, 180°, 270° biome matrices.

Use the existing mathematical rotation system.

---

# 28. MOVE MUST TRANSFORM GLOBAL MICRO TERRAIN

When a piece moves:

the resolved global micro positions of all its biome cells must move with it.

Biome source data remains piece-local.

Global terrain is derived.

---

# 29. MAP VIEW VISUALIZATION

The Map View should clearly show Village Soil versus Natural Grass.

This is still graybox/debug art.

The goal is readability, not final visual quality.

The player/developer must easily perceive:

```text
where Village Soil fragments are
```

and:

```text
how they line up across piece seams
```

Do not display biome names in every micro cell during normal play.

---

# 30. LARGE-CELL SEAMS

For DEBUG mode, allow visualization of:

- large-cell boundaries;
- tetromino boundaries;
- microgrid boundaries.

This will make it possible to verify that a valid Village Soil rectangle crosses those seams correctly.

---

# 31. DO NOT MAKE MICROGRID VISUALS TOO NOISY

Although logic uses 6×6 resolution, normal Map View should not necessarily draw 36 heavy grid borders per large cell.

Suggested:

```text
normal debug terrain view:
show biome color/texture regions

advanced debug:
show 6×6 grid lines
```

The terrain pattern must remain readable as shapes, not visual spreadsheet noise.

---

# 32. REQUIRED FIXTURE ID

Create a dedicated fixture, for example:

```swift
WorldState.buildingPuzzleBiomePrototype
```

or an equivalent clear name.

Do not overwrite unrelated prototype fixtures unless appropriate.

---

# 33. PIECE ROLES / IDS

Use stable semantic identifiers for these five pieces.

Example:

```text
Z1
Z2
L1
T1
S1
```

Do not depend on array ordering to identify which piece owns which mask.

---

# 34. CELL IDS

Keep the A–T labels available for debugging/documentation.

For example:

```text
Z1.A
Z1.B
...
S1.T
```

The runtime does not need strings everywhere, but developers must be able to identify a problematic large cell.

---

# 35. ASCII DEBUG OUTPUT

Support printing each piece with its cell masks.

Example:

```text
Z1 / Cell A

VVVVGG
VVVVGG
VVVGGG
VVVGGG
VVGGGG
VGGGGG
```

This makes it easy to compare implementation against this specification.

---

# 36. FIXTURE VALIDATION TEST

Add a test verifying:

```text
piece count == 5
```

and piece types are exactly:

```text
Z
Z
L
T
S
```

---

# 37. MICROCELL COUNT TEST

Expected:

```text
5 pieces
×
4 large cells
×
36 microcells
=
720 resolved microcells
```

assuming no piece overlap.

Verify exact count.

---

# 38. BIOME TYPE TEST

For this fixture specifically:

every resolved microcell must be either:

```swift
.villageSoil
```

or:

```swift
.naturalGrass
```

No other biome types.

---

# 39. EXACT MASK TESTS

For every cell A–T:

verify the 6×6 source matrix exactly matches this specification.

Do not rely only on screenshots.

---

# 40. ROTATION TESTS

Choose several asymmetric cells such as:

```text
A
E
Q
R
```

Verify exact 90°, 180°, and 270° outputs.

Four rotations must restore the original matrix.

---

# 41. INITIAL ARRANGEMENT TEST

Verify the initial arrangement satisfies the intended constraints.

At minimum:

```text
3×3 Village Soil exists
```

and:

```text
9×15 Village Soil does NOT exist
```

If 6×9 or 6×6 unexpectedly exists at launch, report it.

Do not silently accept accidental triviality.

---

# 42. KNOWN 6×6 SOLUTION

Find and document at least one exact piece arrangement that produces:

```text
6×6 Village Soil
```

Document:

```text
piece positions
piece rotations
rectangle global micro origin
rectangle dimensions
```

This becomes a QA fixture.

---

# 43. KNOWN 6×9 SOLUTION

Find and document at least one arrangement producing:

```text
6×9
```

or:

```text
9×6
```

Village Soil.

Again document exact:

- positions;
- rotations;
- resulting footprint origin.

---

# 44. KNOWN 9×15 SOLUTION

This is critical.

Search for at least one arrangement producing:

```text
9×15
```

or:

```text
15×9
```

Village Soil.

Do not assume the hand-designed masks above guarantee this.

If NO arrangement exists:

STOP and report the failure.

Do not arbitrarily change dozens of masks.

Identify:

- which dimension cannot be achieved;
- what Village Soil fragmentation is preventing it;
- the smallest mask adjustments likely required.

Then make the minimum necessary adjustments and document them.

---

# 45. SOLUTION SEARCH TOOLING

Because five tetrominoes have multiple positions and rotations, create DEBUG/test tooling for searching candidate configurations if useful.

Do NOT build a production puzzle solver.

A development-only brute-force or constrained search is acceptable.

Its purpose is simply to prove:

```text
the fixture is mathematically solvable
```

for the required Village Soil rectangles.

---

# 46. MULTIPLE SOLUTIONS ARE PREFERRED

After finding one valid solution:

check whether multiple different arrangements can satisfy the same footprint.

Do not require exhaustive counting.

The goal is to avoid accidentally creating a puzzle where only one exact hidden configuration works.

Report whether each footprint appears:

```text
highly constrained
moderately flexible
very flexible
```

as a development observation.

Do not turn these descriptions into player-facing difficulty ratings.

---

# 47. DO NOT IMPLEMENT QUEST COMPLETION YET

Do not create:

```text
Quest 1 = Well
Quest 2 = Mara House
...
```

yet.

We are only preparing terrain.

---

# 48. DO NOT IMPLEMENT BUILDING OBJECTS YET

Do not create:

- BuildingNode;
- building inventory;
- building drag;
- building rotation;
- building confirm/cancel;
- building occupancy;
- building overlap checks.

Those belong to the next phase.

---

# 49. DO NOT REUSE OLD EXIT-WAY OBJECTIVE

The old prototype may contain logic such as:

```text
Village → Forest Pass → Outer Wilderness
```

Do not use that as the primary success condition for this fixture.

If legacy systems still exist, preserve them only where needed to avoid breaking unrelated code.

This new fixture is about creating buildable Village Soil geometry.

---

# 50. DEBUG FOOTPRINT SCANNER API

Create a clean domain-level API, for example:

```swift
struct VillageSoilFootprintScanner {

    func findRectangle(
        width: Int,
        height: Int,
        in world: WorldState
    ) -> GlobalMicroRectangle?

    func findAllRectangles(
        width: Int,
        height: Int,
        in world: WorldState
    ) -> [GlobalMicroRectangle]
}
```

Adapt names as needed.

No SpriteKit dependency.

---

# 51. RECTANGLE MODEL

A useful model might be:

```swift
struct GlobalMicroRectangle: Equatable {
    let origin: GlobalMicroPosition
    let width: Int
    let height: Int
}
```

This will later be reusable by building-placement validation.

---

# 52. FUTURE BUILDING SYSTEM COMPATIBILITY

The architecture created here should make the next phase straightforward:

```text
Building definition
↓
footprint dimensions
↓
global micro origin
↓
enumerate covered microcells
↓
check biome
↓
valid / invalid
```

Avoid fixture-specific hacks that would make actual placement difficult later.

---

# 53. MANUAL QA

Perform this in Map View:

1. load the 5-piece fixture;
2. inspect Z1, Z2, L1, T1, S1;
3. verify Village Soil and Grass masks match specification;
4. pan around freely;
5. drag Z1;
6. rotate Z1;
7. verify its internal biome pattern rotates;
8. repeat with L1 and S1;
9. arrange pieces using documented 6×6 solution;
10. enable debug footprint overlay;
11. verify 6×6 region highlights correctly;
12. repeat for 6×9 solution;
13. repeat for 9×15 solution.

---

# 54. DEFINITION OF DONE

This fixture phase is complete only when:

1. exactly five pieces exist: Z, Z, L, T, S;
2. exactly 20 large cells exist;
3. every large cell has a 6×6 micro-biome grid;
4. fixture uses only Village Soil and Natural Grass;
5. masks A–T match the specification or any documented minimum corrections;
6. mixed-biome large cells are common, not exceptional;
7. total resolved microcell count is 720;
8. biome masks move with their tetromino;
9. biome masks rotate with their tetromino;
10. global micro terrain updates correctly;
11. Map View clearly displays Village Soil vs Grass;
12. initial state contains at least one 3×3 Village Soil area;
13. initial state does not contain a 9×15 Village Soil area;
14. domain footprint scanner exists;
15. 3×3 scanning works;
16. 6×6 scanning works;
17. 6×9 / 9×6 scanning works;
18. 9×15 / 15×9 scanning works;
19. one known 6×6 solution is documented;
20. one known 6×9 or 9×6 solution is documented;
21. one known 9×15 or 15×9 solution is documented;
22. known solutions are verified programmatically, not visually assumed;
23. debug footprint overlay can display found regions;
24. building placement has NOT yet been implemented;
25. existing realtime drag / rotate / pan interaction remains functional.

---

# 55. FINAL REPORT

After implementation, provide:

## Fixture

- final five piece shapes;
- final initial positions;
- final initial rotations;
- exact A–T biome masks;
- any mask changes made from this specification and why.

## Statistics

- total Village Soil microcells;
- total Natural Grass microcells;
- percentage of each;
- largest Village Soil rectangle in initial state.

## Solvability

Provide exact known configurations for:

```text
3×3
6×6
6×9 or 9×6
9×15 or 15×9
```

including:

- piece position;
- piece rotation;
- resulting global micro rectangle.

## Architecture

Describe:

- fixture construction;
- global micro terrain resolution;
- footprint scanner;
- rotation behavior;
- Map View biome rendering;
- debug overlays.

## QA

Report:

- automated tests;
- manual tests;
- any unsolved design issues.

Do not continue automatically to building placement.