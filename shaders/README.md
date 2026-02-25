# Shaders (neon cyberpunk aesthetic)

## scanline_vignette.gdshader

Full-screen post-process: **scanlines** + **vignette** for a CRT/synthwave look. Used via `scenes/effects/scanline_overlay.tscn` (CanvasLayer + ColorRect with multiply blend).

- **vignette_strength** (0–1): how much the screen darkens toward the edges.
- **scanline_strength** (0–1): darkness of horizontal scanlines.
- **scanline_freq**: number of scanlines (higher = finer).

Applied in: menu, endless (main), and story level scenes.

## neon_glow.gdshader

Optional per-item shader for **neon glow** on UI (e.g. power bar fill, buttons). Brightens and tints with a glow color. Assign as `CanvasItemMaterial` / `ShaderMaterial` on a ColorRect or TextureRect.

- **glow_power**: brightness multiplier.
- **glow_color**: tint color and intensity (alpha).

You can also use Godot’s built-in **glow** on CanvasItem materials for a similar effect without a custom shader.
