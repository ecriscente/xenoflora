# Xenoflora

A 2D Real-Time Strategy (RTS) game inspired by Eufloria/Dyson, built with Godot 4 and GDScript.

## Overview

Xenoflora is a minimalist space strategy game where you colonize asteroids, manage swarms of spores, and compete against AI opponents for control of the solar system. Using boids-based flocking algorithms, your spores move organically across the battlefield, creating mesmerizing visual patterns while engaging in strategic warfare.

## Features (Phase 1 MVP)

- **Procedural Asteroid Generation**: Dynamic asteroid fields with varying stats (Energy, Defense, Speed)
- **Boids Flocking System**: Smooth, organic movement for 500+ units using spatial optimization
- **Strategic Gameplay**: Capture asteroids by overwhelming their defenses
- **AI Opponent**: Greedy AI that challenges your tactical decisions
- **Minimalist Aesthetics**: Clean, vector-style visuals with neon color schemes

## Technology Stack

- **Engine**: Godot 4.x
- **Language**: GDScript (Python-like syntax)
- **Backend** (Phase 2): FastAPI for multiplayer
- **Target Platform**: Desktop (with future Android support)

## Project Structure

```
eufloria-clone-claude/
├── project.godot           # Godot project configuration
├── scenes/                 # Game scenes (.tscn files)
│   ├── main/              # Root and world scenes
│   ├── asteroids/         # Asteroid templates
│   ├── units/             # Spore unit templates
│   └── ui/                # HUD and UI components
├── scripts/                # GDScript source code
│   ├── core/              # Game manager and state
│   ├── entities/          # Asteroids and units
│   ├── ai/                # AI controller
│   ├── systems/           # Boids, combat, generation
│   └── ui/                # UI controllers
├── assets/                 # Art, fonts, audio
└── backend/                # FastAPI backend (future)
```

## Getting Started

### Prerequisites

- Godot 4.3 or newer
- Git

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd eufloria-clone-claude
   ```

2. Open the project in Godot:
   - Launch Godot 4
   - Click "Import"
   - Navigate to the project folder
   - Select `project.godot`

3. Run the game:
   - Press F5 or click the "Play" button

## Gameplay

### Controls

- **Left-click**: Select an owned asteroid
- **Right-click**: Send 50% of spores to target asteroid

### Objective

Capture all enemy asteroids by overwhelming them with your spore swarms!

## Development Roadmap

### Phase 1: Core Gameplay (Current)
- [x] Project setup
- [ ] Procedural asteroid generation
- [ ] Player selection and input
- [ ] Basic spore movement
- [ ] Combat system
- [ ] Boids flocking implementation
- [ ] AI opponent
- [ ] Production mechanics
- [ ] Win/loss conditions

### Phase 2: Growth & Polish
- [ ] Tree building system
- [ ] Enhanced visuals and shaders
- [ ] Sound effects and music
- [ ] Balance tuning

### Phase 3: Multiplayer
- [ ] FastAPI backend
- [ ] Async multiplayer (ghost battles)
- [ ] Leaderboards and matchmaking

### Phase 4: Mobile
- [ ] Touch controls
- [ ] Android optimization
- [ ] Mobile UI adaptations

## Performance Targets

- **60 FPS** with 500 spores (desktop)
- **30 FPS** with 1000 spores
- Optimized boids using spatial grid (O(n) instead of O(n²))

## Architecture Highlights

### Boids System
The flocking algorithm uses spatial partitioning to efficiently handle hundreds of units:
- Spatial grid: 100x100 pixel cells
- Only checks neighbors in nearby cells
- Staggered updates: 1/3 of units per frame

### Combat
Simple but effective:
```
if attackers > defenders * defense_bonus:
    capture_asteroid()
```

### Serialization
Game state is JSON-ready from day 1 for easy multiplayer integration in Phase 2.

## Contributing

This is currently a solo development project, but feedback and suggestions are welcome!

## License

[To be determined]

## Acknowledgments

- Inspired by **Eufloria** (Rudolf Kremers and Alex May)
- Built with **Godot Engine**
- Boids algorithm by **Craig Reynolds**

---

**Current Version**: 0.1.0-alpha
**Status**: In Development - Phase 1 MVP
