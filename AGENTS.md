# Moikopi – Agent Instructions

Moikopi is a 2D vertical platformer game built with **Godot 4.6** (GL Compatibility renderer) using **GDScript**. There are no external package dependencies, databases, or backend services.

## Project structure

- `project.godot` — Engine config (entry scene: `scenes/menu.tscn`)
- `scripts/` — GDScript source files (player, level, game_manager, audio_manager, ui, menu, background, story_level, platform, cutscene_trigger)
- `scenes/` — Godot `.tscn` scene files
- `scenes/story/` — Story mode levels (`level_01.tscn` through `level_05.tscn`), plus `Platform.tscn`, `Goal.tscn`, `CutsceneTrigger.tscn`
- `shaders/` — GLSL shaders (scanline_vignette, neon_glow)
- `assets/` — Sprites, backgrounds, audio (WAV)
- `build/` — Pre-built exports (Android APK, Web HTML5)
- Autoloads: `GameManager`, `AudioManager`

## Cursor Cloud specific instructions

### Running the game

Godot 4.6 is installed at `/usr/local/bin/godot`. To run the game:

```
cd /workspace && godot --path . --rendering-method gl_compatibility
```

The VM has display `:1` (Xvfb) running. Godot uses **llvmpipe** (software OpenGL) — this works fine but expect V-Sync warnings you can ignore.

### Known caveats

- **No audio device**: ALSA errors about "Unknown PCM default" are expected. Godot falls back to a dummy audio driver. This does not affect gameplay.
- **Checkerboard background**: Some background tiles may render as a checkerboard pattern under software rendering. This is a rendering artefact from llvmpipe, not a project bug.
- **No package manager / no dependencies**: There is nothing to `npm install` or `pip install`. The update script only ensures the Godot binary is present.
- **No automated test suite**: This project has no unit/integration tests. Validation is done by running the game and playing it (press A/D to jump left/right).
- **No linter**: GDScript does not have a standard standalone linter in this project. `godot --headless --check-only --script <file>` can check individual scripts, but autoload singletons will fail to resolve in isolation (this is expected).

### Controls (for manual testing)

| Action | Key |
|--------|-----|
| Jump left | A or Left Arrow (hold to charge, release to jump) |
| Jump right | D or Right Arrow (hold to charge, release to jump) |
| Restart | R |
| Menu | Escape |

### Story mode

Story mode has 5 levels chained via `next_level_path`. See `scenes/story/STORYLINE.md` for the narrative design and `scenes/story/README.md` for how to create/edit levels. To load a specific story level directly:

```
godot --path . --rendering-method gl_compatibility res://scenes/story/level_03.tscn
```

The `game_manager.gd` `STORY_LEVELS` array must list all story level paths. Level 5 (final) has no `next_level_path`, so it returns to the menu on completion.

### Import step

After pulling changes, import assets before running:

```
godot --headless --import
```

This regenerates the `.godot/` cache directory (which is gitignored).
