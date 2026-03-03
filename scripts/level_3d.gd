extends Node3D

## 3D vertical level: platforms in X-Y plane (Y up). Same gameplay as 2D.
## Platform data: [x, y_center, width, height]; depth is constant.
## GameManager uses effective Y = -world Y so finish_y/death_y are set accordingly.

const PLATFORM_DEPTH := 6.0
const VIEWPORT_WIDTH := 32.0  # Same relative scale as 2D (320/10)

var platforms: Array = [
	# Starting ground
	[16, 0, 24, 2],
	# Zigzag up
	[22, 8, 5, 1],
	[10, 14, 5, 1],
	[24, 20, 5, 1],
	[8, 26, 5, 1],
	# Goal platform
	[12, 34, 14, 1.2],
]

var platform_color := Color(0.00, 0.75, 0.85, 0.9)
var platform_alt := Color(0.85, 0.15, 0.75, 0.9)
var rest_color := Color(0.25, 0.15, 0.45, 0.95)
var finish_color := Color(0.00, 1.0, 1.0, 1.0)
var ground_color := Color(0.12, 0.05, 0.25, 1.0)

var endless_color_a := Color(0.00, 0.65, 0.80, 0.9)
var endless_color_b := Color(0.75, 0.10, 0.70, 0.9)
var endless_rest := Color(0.20, 0.10, 0.40, 0.95)

const DEATH_Y_EFFECTIVE := 55.0   # Effective: player dies when -global_position.y > 55 (i.e. below y=-55)
const GEN_LOOK_AHEAD := 60.0
const GEN_CHUNK_SIZE := 12
const GEN_GAP_MIN := 4.5
const GEN_GAP_MAX := 6.5
const GEN_WIDTH_MAX := 4.5
const GEN_WIDTH_MIN := 1.8
const GEN_REST_INTERVAL := 10

var _gen_y: float = 0.0
var _gen_side: int = 1
var _gen_count: int = 0
var _rng := RandomNumberGenerator.new()
var _player: CharacterBody3D = null

var _prev_x: float = 0.0
var _prev_w: float = 0.0
var _prev_y: float = 0.0


func _ready() -> void:
	var goal_plat: Array = platforms[-1]
	# Effective Y = -world Y; goal triggers when player_y <= finish_y
	var goal_top_y: float = goal_plat[1] + goal_plat[3] * 0.5
	GameManager.finish_y = -goal_top_y
	GameManager.death_y = DEATH_Y_EFFECTIVE

	for i in range(platforms.size()):
		var p: Array = platforms[i]
		var color: Color
		var is_last := (i == platforms.size() - 1)
		var is_first := (i == 0)
		if is_last:
			color = finish_color
		elif is_first:
			color = ground_color
		elif p[2] >= 10:
			color = rest_color
		elif i % 2 == 0:
			color = platform_color
		else:
			color = platform_alt
		_create_platform(p[0], p[1], p[2], p[3], color)

	_gen_y = goal_plat[1] + 6.0
	_gen_side = 1
	_rng.randomize()
	_prev_x = goal_plat[0]
	_prev_w = goal_plat[2]
	_prev_y = goal_plat[1]

	AudioManager.play_bgm()


func _process(_delta: float) -> void:
	if _player == null:
		_player = get_node_or_null("../Player3D")
		return
	# Generate when player climbs near the next chunk (world Y increases as we go up)
	if _player.global_position.y > _gen_y - GEN_LOOK_AHEAD:
		_generate_chunk()


func _generate_chunk() -> void:
	for i in range(GEN_CHUNK_SIZE):
		_gen_count += 1
		var difficulty := clampf(float(_gen_count) / 100.0, 0.0, 1.0)
		var gap := GEN_GAP_MIN + _rng.randf() * (GEN_GAP_MAX - GEN_GAP_MIN)
		gap += difficulty * 1.0
		_gen_y += gap

		var is_rest := (_gen_count % GEN_REST_INTERVAL == 0)
		var x: float
		var w: float
		if is_rest:
			w = 11.0 + _rng.randf() * 4.0
			x = (VIEWPORT_WIDTH - w) * 0.5 + _rng.randf_range(-2.0, 2.0)
			x = clampf(x, 1.0, VIEWPORT_WIDTH - w - 1.0)
		else:
			_gen_side *= -1
			w = lerpf(GEN_WIDTH_MAX, GEN_WIDTH_MIN, difficulty)
			w += _rng.randf_range(-0.5, 0.5)
			w = clampf(w, GEN_WIDTH_MIN, GEN_WIDTH_MAX)
			if _gen_side > 0:
				x = VIEWPORT_WIDTH * 0.5 + _rng.randf_range(1.0, VIEWPORT_WIDTH * 0.5 - w - 1.0)
			else:
				x = _rng.randf_range(1.0, VIEWPORT_WIDTH * 0.5 - 1.0)
			x = clampf(x, 0.5, VIEWPORT_WIDTH - w - 0.5)

		var color: Color
		if is_rest:
			color = endless_rest
		else:
			color = endless_color_a if _gen_count % 2 == 0 else endless_color_b
		_create_platform(x, _gen_y, w, 0.8, color)
		_prev_x = x
		_prev_w = w
		_prev_y = _gen_y


func _create_platform(center_x: float, center_y: float, w: float, h: float, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = Vector3(center_x, center_y, 0)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(w, h, PLATFORM_DEPTH)
	col.shape = box
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(w, h, PLATFORM_DEPTH)
	mesh_inst.mesh = box_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	add_child(body)
