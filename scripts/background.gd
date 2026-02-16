extends Node2D

## Forest background: layered parallax textures with weather-responsive sky.
## Computes rain_factor from player height so other systems (rain, audio) can read it.

const VIEWPORT_W := 320.0
const VIEWPORT_H := 180.0

# Sky gradient colours
const SKY_RAIN_TOP := Color(0.05, 0.07, 0.12, 1.0)
const SKY_RAIN_BOT := Color(0.04, 0.05, 0.08, 1.0)
const SKY_CLEAR_TOP := Color(0.10, 0.16, 0.09, 1.0)
const SKY_CLEAR_BOT := Color(0.06, 0.08, 0.05, 1.0)

# Rain thresholds (height in meters / pixels)
const RAIN_FULL_HEIGHT := 1000.0
const RAIN_FADE_RANGE := 200.0

# Layer textures (loaded at runtime so Godot import can happen first)
var _tex_far: Texture2D = null
var _tex_mid: Texture2D = null
var _tex_near: Texture2D = null

# Parallax settings per layer: [parallax_factor, draw_alpha]
# Lower parallax = further away = scrolls slower
var _layer_settings: Array = [
	[0.10, 1.0],    # Far: very slow, fully opaque (base layer)
	[0.25, 0.75],   # Mid: moderate, semi-transparent for depth blending
	[0.45, 1.0],    # Near: faster, full opacity (image has alpha channel)
]

var _camera: Camera2D = null
var rain_factor: float = 1.0  # 1.0 = full rain, 0.0 = clear sky


func _ready() -> void:
	_tex_far = load("res://assets/bg/bg_far.png")
	_tex_mid = load("res://assets/bg/bg_mid.png")
	_tex_near = load("res://assets/bg/bg_near.png")


func _process(_delta: float) -> void:
	if _camera == null:
		var player := get_node_or_null("../Player")
		if player:
			_camera = player.get_node_or_null("Camera2D")
		return

	var height := GameManager.start_y - _camera.global_position.y
	rain_factor = clampf(1.0 - (height - RAIN_FULL_HEIGHT) / RAIN_FADE_RANGE, 0.0, 1.0)

	queue_redraw()


func _draw() -> void:
	if _camera == null or _tex_far == null:
		return

	var cam_x := _camera.global_position.x
	var cam_y := _camera.global_position.y
	var screen_left := cam_x - VIEWPORT_W * 0.5
	var screen_top := cam_y - VIEWPORT_H * 0.5

	# --- Sky gradient (shifts from rainy blue-grey to forest green) ---
	var sky_top := SKY_RAIN_TOP.lerp(SKY_CLEAR_TOP, 1.0 - rain_factor)
	var sky_bot := SKY_RAIN_BOT.lerp(SKY_CLEAR_BOT, 1.0 - rain_factor)
	_draw_sky(screen_left, screen_top, sky_top, sky_bot)

	# --- Parallax forest layers ---
	var textures: Array[Texture2D] = [_tex_far, _tex_mid, _tex_near]
	for i in range(textures.size()):
		var tex: Texture2D = textures[i]
		var parallax: float = _layer_settings[i][0]
		var alpha: float = _layer_settings[i][1]
		_draw_parallax_layer(tex, parallax, alpha, cam_y, screen_left, screen_top)

	# --- Rain mood overlay (subtle blue tint) ---
	if rain_factor > 0.01:
		var tint := Color(0.05, 0.08, 0.15, 0.10 * rain_factor)
		draw_rect(Rect2(screen_left - 20, screen_top - 20,
						VIEWPORT_W + 40, VIEWPORT_H + 40), tint)


func _draw_sky(x: float, y: float, top_col: Color, bot_col: Color) -> void:
	var margin := 20.0
	var w := VIEWPORT_W + margin * 2.0
	var h := VIEWPORT_H + margin * 2.0
	var bands := 8
	var band_h := h / float(bands)
	for b in range(bands):
		var frac := (float(b) + 0.5) / float(bands)
		var col := top_col.lerp(bot_col, frac)
		draw_rect(Rect2(x - margin, y - margin + band_h * float(b),
						w, band_h + 1.0), col)


func _draw_parallax_layer(tex: Texture2D, parallax: float, alpha: float,
						   cam_y: float, screen_left: float,
						   screen_top: float) -> void:
	var tex_w := float(tex.get_width())
	var tex_h := float(tex.get_height())

	# Parallax offset: how much the layer lags behind the camera
	var parallax_offset := cam_y * (1.0 - parallax)

	# First tile index that could be on-screen
	var first_n := int(floor((screen_top - parallax_offset) / tex_h)) - 1

	var tint := Color(1.0, 1.0, 1.0, alpha)
	var y := float(first_n) * tex_h + parallax_offset

	while y < screen_top + VIEWPORT_H + tex_h:
		draw_texture_rect(tex, Rect2(screen_left, y, tex_w, tex_h),
						  false, tint)
		y += tex_h
