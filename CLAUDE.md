# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Xenoflora is a 2D real-time strategy game inspired by Eufloria/Dyson, built with Godot 4.5 and GDScript. Players colonize asteroids using organic spore-based units with boids flocking behavior to compete against an AI opponent.

**Current Status:** Phase 1 MVP Complete ✅
**Engine:** Godot 4.5.1
**Language:** GDScript

## Essential Commands

### Running the Game
```bash
# Open project in Godot Editor
godot-4 project.godot

# Run game directly (F5 in editor)
godot-4 --path . scenes/main/main.tscn
```

### Development
```bash
# Run headless (for testing scripts)
godot-4 --headless --script <script_path>

# Export for desktop platforms
godot-4 --export-release "Linux/X11" build/xenoflora-linux
godot-4 --export-release "Windows Desktop" build/xenoflora-win.exe
```

### Testing
```bash
# Run all tests
godot-4 --headless -s --path . addons/gdUnit4/bin/GdUnitCmdTool.gd --add tests/ --ignoreHeadlessMode --audio-driver Dummy
```

See the Testing section below for detailed information.

## Architecture Overview

### Autoload Singletons (Global Systems)

Godot uses autoload singletons for globally accessible systems. These are critical to understand:

1. **GameManager** (`scripts/core/game_manager.gd`)
   - Central game state coordinator
   - Manages asteroid and spore group collections
   - Handles combat resolution via `process_combat()`
   - Emits signals for major game events
   - **Key signals:** `game_initialized`, `asteroid_selected`, `asteroid_captured`, `game_over`

2. **BoidsSystem** (`scripts/systems/boids_system.gd`)
   - Spatial grid for efficient neighbor queries (100x100 pixel cells)
   - Manages unit registration/unregistration
   - Staggered updates: processes 1/3 of units per frame
   - **Performance critical:** Uses spatial partitioning to avoid O(n²) neighbor searches
   - **Key methods:** `register_unit()`, `unregister_unit()`, `get_neighbors()`

### Signal-Driven Architecture

The game uses Godot's signal system for decoupled communication:

```gdscript
# GameManager signals (scripts/core/game_manager.gd)
signal game_initialized()
signal asteroid_selected(asteroid: Asteroid)
signal asteroid_deselected()
signal spores_sent(from: Asteroid, to: Asteroid, count: int)
signal asteroid_captured(asteroid: Asteroid, new_owner: int)
signal game_over(winner: int)

# Asteroid signals (scripts/entities/asteroid.gd)
signal spores_changed(new_count: int)
signal owner_changed(new_owner: int)
signal clicked(asteroid: Asteroid)
```

Always connect to signals rather than direct coupling between systems.

### Combat System

Combat resolution happens in `GameManager.process_combat()`:

```gdscript
# Capture threshold
if attacker_count > (defender_count * defense_bonus):
    capture_asteroid()
    remaining_spores = attacker_count - effective_defense
else:
    # Defenders lose spores proportional to attack strength
    defender_losses = attacker_count / defense_bonus
```

**Important:** Friendly reinforcements bypass combat (checked via `owner_id` match).

### Boids Flocking Implementation

The boids system uses four weighted forces:

1. **Separation** (weight 1.8) - Avoid crowding, minimum 20px distance
2. **Alignment** (weight 0.8) - Match neighbor velocities
3. **Cohesion** (weight 1.2) - Move toward group center
4. **Targeting** (weight 3.0) - Highest priority, ensures units reach destination

Force calculations occur in `SporeUnit.apply_boids()` (scripts/entities/spore_unit.gd).

**Performance optimization:**
- Spatial grid provides O(1) cell lookup (vs O(n) brute force)
- Only checks 3x3 neighbor cells (9 cells max)
- Staggered updates: `delta * UPDATE_GROUPS` compensates for processing 1/3 units per frame
- Result: 10x performance improvement (500 spores @ 60 FPS)

### Scene Structure

```
Main (scenes/main/main.tscn)
├── GameWorld (game_world.gd)
│   ├── Background (ColorRect)
│   ├── Camera2D (CameraController)
│   ├── AsteroidContainer (Node2D) - asteroids added here
│   ├── SporeContainer (Node2D) - spore groups added here
│   └── AIController (ai/ai_controller.gd)
├── InputHandler (systems/input_handler.gd)
└── HUD (CanvasLayer - ui/hud.tscn)
```

### Critical Node References

GameManager requires `asteroid_container` and `spore_container` to be set by the main scene before `initialize_game()`. These are assigned in the main scene's `_ready()`.

## Common Development Patterns

### Creating Spore Groups

Always use `GameManager.send_spores()` rather than creating SporeGroup directly:

```gdscript
# Correct
GameManager.send_spores(source_asteroid, target_asteroid, 50)

# Incorrect - bypasses game state tracking
var group = SporeGroup.new()
```

### Ownership Convention

Owner IDs follow this pattern consistently:
- `-1` = Neutral (gray)
- `0` = Player (cyan)
- `1` = AI (red)

### Asteroid Property Setters

Asteroid uses property setters that trigger visual updates:

```gdscript
# These automatically update visuals
asteroid.owner_id = 0  # Triggers _update_visual_state()
asteroid.current_spores = 25  # Triggers _update_spore_label()
asteroid.radius = 60.0  # Triggers _update_collision_shape() and _update_sprite_scale()
```

### Method Naming: `set_owner()` Conflict

**CRITICAL:** Never use `set_owner()` - it conflicts with Godot's built-in Node method. Use `change_owner()` instead. This was a major bug fix during development (see git history).

### Memory Management

Always validate nodes before accessing:

```gdscript
if is_instance_valid(unit):
    # Safe to access unit properties
```

The BoidsSystem performs automatic cleanup of invalid units every frame in `_update_spatial_grid()`.

## AI System

The AI opponent (`scripts/ai/ai_controller.gd`) uses a greedy strategy:

1. Runs every 3 seconds (`ai_turn_interval`)
2. For each owned asteroid with 15+ spores:
   - Scores targets by `(distance/1000) + (defense/200)` - lower is better
   - Calculates required spores: `defenders * defense_bonus + 1`
   - Attacks if owned spores >= required × 1.2 (safety margin)
   - Sends 50% of available spores
3. Allows up to 2 attacks per turn (`max_attacks_per_turn`)

**Known limitation:** AI is currently greedy-only with no strategic planning. Future phases will add territory control and coordinated attacks.

## Production System

Asteroids produce spores when owned:

```gdscript
# Production formula (in asteroid._process)
production_rate = 1.0  # base spores/second
multiplier = (energy/100) * defense_bonus
accumulator += production_rate * multiplier * delta

# Cap: energy * 2 spores per asteroid
```

## Performance Considerations

### Target Metrics
- 500 spores @ 60 FPS (achieved ✅)
- Frame budget: 16.67ms (boids currently ~8ms)

### Optimization Techniques in Use
1. Spatial grid partitioning (100px cells)
2. Staggered updates (UPDATE_GROUPS = 3)
3. Neighbor validation with `is_instance_valid()`
4. Cell cleanup for empty grids

### Future Optimizations (if needed)
- MultiMeshInstance2D for 1000+ spores
- Object pooling for spore nodes
- LOD system for distant units
- GPU particles for trails

## Serialization

Game state can be serialized via `GameManager.serialize_state()` which returns a JSON-ready dictionary. Deserialization is stubbed but not implemented (planned for Phase 2 multiplayer).

## Code Style Notes

- GDScript follows Python-like syntax with static typing where possible
- Type hints used sparingly due to circular dependency issues (see git history)
- Comments use `##` for documentation comments (appear in editor tooltips)
- Signals declared at top of scripts for visibility
- Exported variables (`@export`) appear before regular variables

## Known Issues & Limitations

1. **No save/load system** - Game state serialization exists but not persistence
2. **Single difficulty level** - AI cannot be adjusted
3. **Fixed asteroid count** - Always generates 15 asteroids
4. **No unit tests** - Manual testing only
5. **Desktop only** - No mobile touch controls

## Future Development Notes

See ROADMAP.md for detailed plans, but key Phase 2 priorities:

1. **Trees & Upgrades** - Strategic depth (production/defense/speed trees)
2. **Visual Polish** - Particle systems, shaders, improved sprites
3. **Multiplayer Foundation** - FastAPI backend with WebSockets

The codebase is designed with multiplayer in mind - serialization methods exist, and game state is centralized in GameManager for easy synchronization.

## Common Gotchas

1. **Coordinate system:** Play area is centered at origin (-800,-400 to 800,400), not top-left
2. **Camera position:** Camera starts at (0,0), not (960,540)
3. **Pause mode:** Game over UI uses `process_mode = ALWAYS` to work when tree is paused
4. **Restart button:** Must use `call_deferred()` for scene reloading to avoid timing issues
5. **SporeGroup cleanup:** Groups auto-remove via signal when arriving at target
6. **Friendly fire:** Check `owner_id` match before calling `process_combat()`

## File Organization

```
scripts/
├── core/           # Game-wide managers (GameManager)
├── entities/       # Game objects (Asteroid, SporeUnit, SporeGroup)
├── systems/        # Reusable systems (BoidsSystem, AsteroidGenerator, Input, Camera)
├── ai/             # AI controllers
└── ui/             # UI controllers

scenes/
├── main/           # Root game scenes
├── asteroids/      # Asteroid prefab (.tscn)
├── units/          # Spore unit prefabs
└── ui/             # HUD and UI scenes

assets/
├── sprites/        # SVG sprite assets (asteroid_player.svg, etc.)
├── fonts/          # Font files
└── audio/          # Sound effects and music (future)
```

## Testing

The project uses **GdUnit4** for automated testing (installed in `addons/gdUnit4`).

### Running Tests

```bash
# Via Godot Editor (recommended)
# 1. Open project
# 2. Go to Project → Project Settings → Plugins
# 3. Enable "gdUnit4" plugin
# 4. Click GdUnit4 tab at bottom → Run All

# Via command line
godot-4 --headless -s --path . addons/gdUnit4/bin/GdUnitCmdTool.gd \
  --add tests/ --ignoreHeadlessMode --audio-driver Dummy
```

### Existing Test Coverage

- `tests/test_asteroid_generator.gd` - Asteroid generation, overlap checking, property ranges
- `tests/test_combat_system.gd` - Combat resolution, defense bonuses, edge cases
- See `tests/README.md` for detailed testing guide

### Writing New Tests

1. Create `tests/test_<feature>.gd`
2. Extend `GdUnitTestSuite`
3. Write functions prefixed with `test_`
4. Use GdUnit4 assertions: `assert_int()`, `assert_float()`, `assert_bool()`, etc.

**Example:**
```gdscript
extends GdUnitTestSuite

func test_asteroid_production():
    var asteroid = create_test_asteroid(0, 10)
    asteroid.produce_spores(1.0)  # 1 second
    assert_int(asteroid.current_spores).is_greater(10)
```

## Git Workflow

The project uses conventional commits with descriptive messages ending in the Claude Code signature. See recent commits for examples of the established pattern.
