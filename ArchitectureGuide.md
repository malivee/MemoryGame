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
