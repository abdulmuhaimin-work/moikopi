extends Node2D

## Neon cyberpunk background: dark gradient + parallax grid lines.
## Exposes rain_factor (kept for compatibility; not used for weather).

const VIEWPORT_W := 320.0
const VIEWPORT_H := 180.0

# Neon sky gradient (dark purple/blue)
const SKY_TOP := Color(0.06, 0.02, 0.18, 1.0)
const SKY_BOT := Color(0.03, 0.01, 0.10, 1.0)

# Zone tint colors (story mode)
const ZONE_TOP := [Color(0.06, 0.02, 0.18, 1.0), Color(0.08, 0.02, 0.22, 1.0), Color(0.04, 0.08, 0.18, 1.0)]
const ZONE_BOT := [Color(0.03, 0.01, 0.10, 1.0), Color(0.05, 0.01, 0.14, 1.0), Color(0.02, 0.04, 0.12, 1.0)]

# Grid line color (subtle neon)
const GRID_COLOR := Color(0.15, 0.05, 0.35, 0.5)
const GRID_SPACING := 40.0

var _camera: Camera2D = null
var rain_factor: float = 1.0  # Kept for script compatibility; not used
var _zone_id: int = 0
var _zone_tint: float = 0.0  # lerp toward zone


func _process(delta: float) -> void:
	if _camera == null:
		var player := get_node_or_null("../Player")
		if player:
			_camera = player.get_node_or_null("Camera2D")
		return
	_zone_tint = move_toward(_zone_tint, 1.0, delta * 1.5)
	queue_redraw()


func set_zone(zone_id: int) -> void:
	_zone_id = clampi(zone_id, 0, ZONE_TOP.size() - 1)
	_zone_tint = 0.0


func _draw() -> void:
	if _camera == null:
		return

	var cam_x := _camera.global_position.x
	var cam_y := _camera.global_position.y
	var screen_left := cam_x - VIEWPORT_W * 0.5
	var screen_top := cam_y - VIEWPORT_H * 0.5
	var margin := 30.0

	# --- Dark gradient background ---
	var w := VIEWPORT_W + margin * 2.0
	var h := VIEWPORT_H + margin * 2.0
	var bands := 12
	var band_h := h / float(bands)
	var top_col := SKY_TOP.lerp(ZONE_TOP[_zone_id], _zone_tint)
	var bot_col := SKY_BOT.lerp(ZONE_BOT[_zone_id], _zone_tint)
	for b in range(bands):
		var frac := (float(b) + 0.5) / float(bands)
		var col := top_col.lerp(bot_col, frac)
		draw_rect(Rect2(screen_left - margin, screen_top - margin + band_h * float(b),
						w, band_h + 1.0), col)

	# --- Parallax grid lines (horizontal + vertical) ---
	var grid_parallax := 0.3
	var offset_y := cam_y * (1.0 - grid_parallax)
	var offset_x := cam_x * (1.0 - grid_parallax)

	# Horizontal lines
	var line_y: float = floor((screen_top - offset_y) / GRID_SPACING) * GRID_SPACING + offset_y
	while line_y < screen_top + VIEWPORT_H + GRID_SPACING:
		draw_line(Vector2(screen_left - margin, line_y),
				  Vector2(screen_left + VIEWPORT_W + margin, line_y), GRID_COLOR)
		line_y += GRID_SPACING

	# Vertical lines
	var line_x: float = floor((screen_left - offset_x) / GRID_SPACING) * GRID_SPACING + offset_x
	while line_x < screen_left + VIEWPORT_W + GRID_SPACING:
		draw_line(Vector2(line_x, screen_top - margin),
				  Vector2(line_x, screen_top + VIEWPORT_H + margin), GRID_COLOR)
		line_x += GRID_SPACING
