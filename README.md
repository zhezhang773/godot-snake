# 🐍 Snake Game - Godot 4

A classic Snake game built with Godot 4.5 with rich features and visual polish.

## 🎮 Controls

| Action        | Key              |
|---------------|------------------|
| Move Up       | `W` / `↑`        |
| Move Down     | `S` / `↓`        |
| Move Left     | `A` / `←`        |
| Move Right    | `D` / `→`        |
| Pause/Resume  | `ESC`            |
| Restart       | `SPACE` (after game over) |

## 🚀 How to Run

1. Download and install [Godot 4.2+](https://godotengine.org/download)
2. Open Godot Editor
3. Click **Import** and select `project.godot` from this folder
4. Press **F5** to run

## 📁 Project Structure

```
G:\autoclawcode\
├── project.godot           # Godot project configuration
├── icon.svg                # Project icon
├── README.md               # This file
├── scenes/
│   └── Main.tscn           # Main game scene (with AudioManager)
└── scripts/
    ├── Main.gd             # All game logic
    └── AudioManager.gd     # Procedural music & SFX
```

## ✨ Features

### Core Gameplay
- **Pure code rendering** — no external assets needed
- **Smooth animations** — pulsing food, gradient snake body
- **Progressive difficulty** — speed increases as you eat
- **High score persistence** — saved between sessions
- **Responsive UI** — start screen, pause screen, game over overlay
- **Visual polish** — glow effects, rounded corners, eye tracking

### Special Fruits (v2.0)
- **[G] Ghost** — Pass through your own body for 20 seconds
- **[W] Wall Stop** — Become immune to wall collisions for 15 seconds
- **[F] Food Rain** — Spawns 4-8 extra food items on the board

### Danger System
- **Bomb Traps** — Some fruits are disguised bombs!
- Reveal when snake gets within 3 cells (Chebyshev distance)
- Bomb blinks between fruit and bomb appearance
- Countdown timer (5s) before self-destruct
- Eating a bomb costs 30 points; score below 0 = death

### New in v2.0
- **🧱 Obstacle System** — Rocks spawn on the grid as you score higher (every 50 pts)
- **🔥 Combo System** — Eat food quickly for bonus points (x3+ combo gives extra score)
- **📊 Level Progression** — Levels increase every 50 points, each level speeds up more
- **💥 Particle Effects** — Burst particles on eating food, explosions, and death
- **📢 Floating Score Text** — Score popups (+10, +30, -30) float up from food
- **🎵 Procedural Music** — Chiptune-style background music generated entirely in code
- **🔊 Sound Effects** — Eat chime, special fruit sparkle, bomb ticks, explosion

## 🎯 Game Rules

- Eat the red food to grow and score points (10 pts each)
- Special fruits give 30 pts + combo bonus
- Combo multipliers kick in at x3 (eat quickly within 3 seconds)
- Speed gradually increases + level-ups add extra speed
- Obstacles spawn every 50 points (max 20 on the grid)
- Avoid hitting walls, obstacles, and your own body
- Ghost effect lets you pass through yourself
- Wall Stop effect makes you immune to wall death
- Fill the board to win (theoretically!)

## 🛠 Technical Details

- **Engine**: Godot 4.5
- **Architecture**: Two-file GDScript (Main.gd + AudioManager.gd)
- **Rendering**: `Node2D._draw()` for all visuals
- **Grid**: 16×16 cells, 40px each = 640×640 canvas
- **Input**: Input Map (WASD + Arrow Keys)
- **Audio**: Fully procedural — AudioStreamGenerator for music, synthesized WAV for SFX
- **Physics Layers**: walls, snake, food, obstacles
