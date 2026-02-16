extends Node2D

## Forest background: vertical gradient + parallax tree silhouettes.
## Attach as first child in main scene so it renders behind everything.

const VIEWPORT_W := 320.0
const VIEWPORT_H := 180.0

# Gradient colours (bottom → top)
const COLOR_BOTTOM := Color(0.06, 0.08, 0.05, 1.0)  # Dark forest floor
const COLOR_TOP := Color(0.12, 0.18, 0.10, 1.0)      # Slightly lighter canopy

# Tree silhouette layers (parallax_factor, colour, width_range, count)
var _tree_layers: Array = [
	{ "parallax": 0.15, "color": Color(0.07, 0.10, 0.06, 0.6), "w_min": 12.0, "w_max": 22.0, "count": 6 },
	{ "parallax": 0.25, "color": Color(0.09, 0.13, 0.07, 0.45), "w_min": 8.0, "w_max": 16.0, "count": 8 },
	{ "parallax": 0.35, "color": Color(0.11, 0.15, 0.09, 0.3), "w_min": 5.0, "w_max": 12.0, "count": 10 },
]

# Precomputed tree positions per layer: Array of Array of {x, w, h}
var _trees: Array = []

var _camera: Camera2D = null


func _ready() -> void:
	# The gradient is drawn as a full-screen rect that follows the camera,
	# tinted via _draw() override.
	_seed_trees()


func _process(_delta: float) -> void:
	if _camera == null:
		var player := get_node_or_null("../Player")
		if player:
			_camera = player.get_node_or_null("Camera2D")
		return
	queue_redraw()


func _draw() -> void:
	if _camera == null:
		return

	var cam_y := _camera.global_position.y
	var screen_top := cam_y - VIEWPORT_H * 0.5
	var screen_bottom := cam_y + VIEWPORT_H * 0.5

	# --- Gradient background (fills the visible viewport) ---
	var grad_h := VIEWPORT_H / 8.0
	for i in range(8):
		var frac_top := float(i) / 8.0
		var frac_bot := float(i + 1) / 8.0
		var c_top := COLOR_TOP.lerp(COLOR_BOTTOM, frac_top)
		var c_bot := COLOR_TOP.lerp(COLOR_BOTTOM, frac_bot)
		var y_top := screen_top + grad_h * i
		# Use the average of top/bottom for a simple banded gradient
		var avg := c_top.lerp(c_bot, 0.5)
		draw_rect(Rect2(-50, y_top, VIEWPORT_W + 100, grad_h + 1), avg)

	# --- Tree silhouettes (parallax layers) ---
	for li in range(_tree_layers.size()):
		var layer: Dictionary = _tree_layers[li]
		var pf: float = layer["parallax"]
		var col: Color = layer["color"]
		var trees_in_layer: Array = _trees[li]

		# Parallax offset: trees scroll slower than the camera
		var offset_y := cam_y * (1.0 - pf)

		for tree in trees_in_layer:
			var tx: float = tree["x"]
			var tw: float = tree["w"]
			var th: float = tree["h"]
			var base_y: float = tree["base_y"]

			# Tile the tree column vertically so it always covers the viewport
			var tile_h := th + 200.0
			var shifted_base := base_y + fmod(offset_y, tile_h)
			# Draw a few copies to cover the screen
			for rep in range(-2, 3):
				var ty := shifted_base + rep * tile_h - th
				if ty < screen_bottom + 50 and ty + th > screen_top - 50:
					draw_rect(Rect2(tx, ty, tw, th), col)


func _seed_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345  # Fixed seed for consistent look

	for layer in _tree_layers:
		var layer_trees: Array = []
		var count: int = layer["count"]
		var w_min: float = layer["w_min"]
		var w_max: float = layer["w_max"]

		for i in range(count):
			var tw := rng.randf_range(w_min, w_max)
			# Trees are placed on the left or right edges of the viewport
			var tx: float
			if i % 2 == 0:
				tx = rng.randf_range(-tw * 0.3, 25.0)
			else:
				tx = rng.randf_range(VIEWPORT_W - 25.0, VIEWPORT_W + tw * 0.3)
			var th := rng.randf_range(80.0, 200.0)
			var base_y := rng.randf_range(0.0, 400.0)
			layer_trees.append({ "x": tx, "w": tw, "h": th, "base_y": base_y })

		_trees.append(layer_trees)
