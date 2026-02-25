# Story Mode Levels

Levels are designed in the Godot editor. Duplicate `level_01.tscn` to create new levels.

## Required nodes (under the root StoryLevel node)

- **PlayerStart** (Marker2D) – Where the player spawns. Place it on or just above your starting platform.
- **Goal** (Area2D) – Instance of `Goal.tscn`. When the player’s body enters this area, the level is complete. Place it where you want the level end.
- **Platforms** (Node2D) – Container for platform instances. Add **Platform** instances here.

## Optional nodes

- **CutsceneTrigger** – Instance of `CutsceneTrigger.tscn`. When the player enters, a cutscene runs. In the inspector set:
  - **Cutscene Text** – Text shown in the overlay.
  - **Display Duration** – How long (seconds) the text stays on screen.
- **CutsceneOverlay** – Optional. If you don’t add one, a simple overlay is created at runtime. To style it yourself, add a CanvasLayer named `CutsceneOverlay` with a Panel and Label (e.g. `Panel/MarginContainer/Label`).
- **Background** – Instance of `res://scenes/background.tscn` for the same neon background as endless mode.
- **UI** – Instance of `res://scenes/ui.tscn` for timer, height, and Restart/Menu buttons.

## Root script exports (StoryLevel)

- **Camera Limit Left / Top / Right / Bottom** – Constrain the camera so it doesn’t scroll outside the level.
- **Death Y** – If the player falls below this Y value, they die (e.g. `230` for a level that sits around Y 160).
- **Level Index** – Index of this level (for future level select).
- **Next Level Path** – Scene path of the next story level (e.g. `res://scenes/story/level_02.tscn`). Leave empty to return to the menu after this level.

## Adding platforms

1. Under **Platforms**, add a child and choose **Instantiate Child Scene**.
2. Pick `res://scenes/story/Platform.tscn`.
3. Move the node to the **center** of where you want the platform (the script uses the node position as the platform center).
4. In the inspector set:
   - **Platform Width** / **Platform Height** – Size of the platform.
   - **Platform Color** – Color of the platform (e.g. neon cyan/magenta).

You can mix vertical and horizontal progression by placing platforms in any layout (right, up, left, down, etc.). The camera follows the player within the limits you set.

## Adding cutscenes

1. Add an instance of `CutsceneTrigger.tscn` as a child of the root (or under a group).
2. Move it where the player should trigger it (e.g. on or near a platform).
3. Resize the **CollisionShape2D** so the trigger area fits (e.g. a rectangle the player will walk or land into).
4. Set **Cutscene Text** and **Display Duration** in the inspector.

## Adding a new level to the menu

In `scripts/game_manager.gd`, add your level path to the `STORY_LEVELS` array. The first level (index 0) is the one that opens when you press **Story** on the menu. Use **Next Level Path** on each level to chain to the next.
