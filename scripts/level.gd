extends Node2D

# Vertical level: platforms zigzag upward.
# Platform data: [x, y_top, width, height]
# Viewport: 320x180. Player starts near y=160, finish near y=-2910.
var platforms: Array = [
	# === Starting ground ===
	[40, 160, 240, 20],
	# === Easy first jumps - zigzag up ===
	[180, 115, 50, 8],
	[60, 70, 50, 8],
	[190, 25, 50, 8],
	[50, -20, 50, 8],
	# === Section 2 - moderate gaps ===
	# [185, -70, 45, 8],
	# [40, -120, 45, 8],
	# [195, -170, 45, 8],
	# [55, -220, 45, 8],
	# [180, -270, 45, 8],
	# # === Rest platform ===
	# [70, -325, 180, 8],
	# # === Section 3 - narrower platforms ===
	# [190, -380, 50, 8],
	# [50, -430, 50, 8],
	# [200, -480, 50, 8],
	# [40, -530, 50, 8],
	# [190, -585, 50, 8],
	# [60, -640, 50, 8],
	# # === Rest platform ===
	# [80, -700, 160, 8],
	# # === Section 4 - precision ===
	# [200, -755, 50, 8],
	# [55, -810, 50, 8],
	# [210, -865, 50, 8],
	# [45, -920, 50, 8],
	# [195, -975, 50, 8],
	# [60, -1030, 50, 8],
	# [200, -1085, 50, 8],
	# # === Rest platform ===
	# [75, -1145, 150, 8],
	# # === Section 5 - fast zigzag ===
	# [195, -1195, 50, 8],
	# [65, -1240, 50, 8],
	# [200, -1285, 50, 8],
	# [55, -1330, 50, 8],
	# [195, -1375, 50, 8],
	# [60, -1420, 50, 8],
	# [200, -1465, 50, 8],
	# [50, -1510, 50, 8],
	# # === Rest platform ===
	# [80, -1570, 150, 8],
	# # === Section 6 - long jumps ===
	# [210, -1640, 50, 8],
	# [30, -1710, 50, 8],
	# [220, -1780, 50, 8],
	# [40, -1850, 50, 8],
	# [210, -1920, 50, 8],
	# # === Rest platform ===
	# [70, -1985, 150, 8],
	# # === Section 7 - tiny platforms ===
	# [205, -2045, 50, 8],
	# [50, -2100, 50, 8],
	# [215, -2155, 50, 8],
	# [40, -2210, 50, 8],
	# [205, -2270, 50, 8],
	# [55, -2330, 50, 8],
	# # === Rest platform ===
	# [85, -2395, 150, 8],
	# # === Section 8 - final challenge ===
	# [210, -2455, 50, 8],
	# [40, -2515, 50, 8],
	# [215, -2575, 50, 8],
	# [35, -2640, 50, 8],
	# [210, -2705, 50, 8],
	# [50, -2770, 50, 8],
	# [200, -2840, 28, 8],
	# === FINISH platform (gold) ===
	[50, -70, 150, 12],
]

# Hand-crafted level colors (neon cyberpunk palette)
var platform_color := Color(0.00, 0.75, 0.85, 0.9)
var platform_alt := Color(0.85, 0.15, 0.75, 0.9)
var rest_color := Color(0.25, 0.15, 0.45, 0.95)
var finish_color := Color(0.00, 1.0, 1.0, 1.0)
var ground_color := Color(0.12, 0.05, 0.25, 1.0)

# Endless section colors (neon variants)
var endless_color_a := Color(0.00, 0.65, 0.80, 0.9)
var endless_color_b := Color(0.75, 0.10, 0.70, 0.9)
var endless_rest := Color(0.20, 0.10, 0.40, 0.95)

const DEATH_Y := 220.0  # Below the starting platform
const VIEWPORT_WIDTH := 320.0

# --- Procedural generation state ---
var _gen_y: float = 0.0        # Next Y to generate at (decreasing = higher)
var _gen_side: int = 1         # 1 = place on right half, -1 = left half
var _gen_count: int = 0        # Platforms generated beyond the goal
var _rng := RandomNumberGenerator.new()
var _player: CharacterBody2D = null

const GEN_LOOK_AHEAD := 600.0  # Generate when player is this close (in px)
const GEN_CHUNK_SIZE := 12     # Platforms per generation batch
const GEN_GAP_MIN := 45.0
const GEN_GAP_MAX := 65.0
const GEN_WIDTH_MAX := 45.0
const GEN_WIDTH_MIN := 18.0
const GEN_REST_INTERVAL := 10  # Wide rest platform every N generated

# --- Reachability validation ---
# Track previous platform so we can guarantee every jump is possible.
var _prev_x: float = 0.0
var _prev_w: float = 0.0
var _prev_y: float = 0.0

# Use 92% of MAX_POWER so the player has a comfort margin (doesn't need
# a frame-perfect charge to clear a jump).
const REACH_POWER := 460.0
const REACH_SAMPLES := 25  # Angle samples for the sweep

# --- Neon particle references ---
var _digital_rain_particles: CPUParticles2D = null
var _neon_drift_particles: CPUParticles2D = null
var _cam: Camera2D = null
const DIGITAL_RAIN_AMOUNT := 100
const NEON_DRIFT_AMOUNT := 25


func _ready() -> void:
	# Compute finish Y from the goal (last) platform
	var goal_plat: Array = platforms[-1]
	var finish_y: float = goal_plat[1]  # top-edge Y of the goal platform

	# Tell GameManager where the finish and death lines are
	GameManager.finish_y = finish_y
	GameManager.death_y = DEATH_Y

	# Build hand-crafted platforms
	for i in range(platforms.size()):
		var p: Array = platforms[i]
		var color: Color
		var is_last := (i == platforms.size() - 1)
		var is_first := (i == 0)
		var w: float = p[2]

		if is_last:
			color = finish_color
		elif is_first:
			color = ground_color
		elif w >= 100:
			color = rest_color
		elif i % 2 == 0:
			color = platform_color
		else:
			color = platform_alt

		_create_platform(p[0], p[1], p[2], p[3], color)

	# Labels
	_create_finish_label(finish_y)
	_create_beyond_label(finish_y)

	# Seed procedural generation starting above the goal platform
	_gen_y = finish_y - 60.0
	_gen_side = 1
	_rng.randomize()

	# Initialise previous-platform tracker from the goal platform
	_prev_x = goal_plat[0]
	_prev_w = goal_plat[2]
	_prev_y = finish_y

	# Neon atmosphere particles
	call_deferred("_create_neon_drift_particles")
	call_deferred("_create_digital_rain_particles")

	# Start background music
	AudioManager.play_bgm()


func _process(_delta: float) -> void:
	if _player == null:
		_player = get_node_or_null("../Player")
		return

	# Generate more platforms as the player climbs into the endless section
	if _player.global_position.y < _gen_y + GEN_LOOK_AHEAD:
		_generate_chunk()

	# Update particle positions to follow camera
	_update_particles()


func _generate_chunk() -> void:
	for i in range(GEN_CHUNK_SIZE):
		_gen_count += 1

		# Difficulty ramps from 0 to 1 over the first 100 generated platforms
		var difficulty := clampf(float(_gen_count) / 100.0, 0.0, 1.0)

		# Vertical gap (slightly wider as difficulty increases)
		var gap := GEN_GAP_MIN + _rng.randf() * (GEN_GAP_MAX - GEN_GAP_MIN)
		gap += difficulty * 10.0
		_gen_y -= gap

		var is_rest := (_gen_count % GEN_REST_INTERVAL == 0)
		var x: float
		var w: float

		if is_rest:
			# Wide rest platform roughly centered
			w = 110.0 + _rng.randf() * 40.0
			x = (VIEWPORT_WIDTH - w) * 0.5 + _rng.randf_range(-20.0, 20.0)
			x = clampf(x, 10.0, VIEWPORT_WIDTH - w - 10.0)
		else:
			# Normal platform — zigzag with randomness
			_gen_side *= -1
			w = lerpf(GEN_WIDTH_MAX, GEN_WIDTH_MIN, difficulty)
			w += _rng.randf_range(-5.0, 5.0)
			w = clampf(w, GEN_WIDTH_MIN, GEN_WIDTH_MAX)

			if _gen_side > 0:
				x = VIEWPORT_WIDTH * 0.5 + _rng.randf_range(10.0, VIEWPORT_WIDTH * 0.5 - w - 10.0)
			else:
				x = _rng.randf_range(10.0, VIEWPORT_WIDTH * 0.5 - 10.0)
			x = clampf(x, 5.0, VIEWPORT_WIDTH - w - 5.0)

		# --- Validate reachability & nudge if needed ---
		x = _ensure_reachable(x, w, _gen_y)

		var color: Color
		if is_rest:
			color = endless_rest
		else:
			color = endless_color_a if _gen_count % 2 == 0 else endless_color_b

		_create_platform(x, _gen_y, w, 8.0, color)

		# Add visible guide walls on both sides of rest platforms
		if is_rest:
			_create_rest_walls(x, _gen_y, w)

		# Update tracker for next iteration
		_prev_x = x
		_prev_w = w
		_prev_y = _gen_y


# ---------------------------------------------------------------------------
# Physics-based reachability check
# ---------------------------------------------------------------------------

func _can_reach(fx: float, fw: float, fy: float,
				tx: float, tw: float, ty: float) -> bool:
	"""Return true if a jump from platform (fx,fy,fw) can land on (tx,ty,tw).
	Sweeps REACH_SAMPLES angles at REACH_POWER in both left and right arcs."""
	var dy := fy - ty  # Positive when target is above (Y points down)
	if dy <= 0.0:
		return true  # Target at same height or below — trivially reachable

	var fcx := fx + fw * 0.5
	var tcx := tx + tw * 0.5
	var going_right := tcx >= fcx

	# The player launches from the platform edge closest to the target
	var launch_x := (fx + fw) if going_right else fx

	# Angle sweep for the matching direction
	var a_lo: float
	var a_hi: float
	if going_right:
		a_lo = deg_to_rad(35.0)   # ANGLE_RIGHT_MIN
		a_hi = deg_to_rad(85.0)   # ANGLE_RIGHT_MAX
	else:
		a_lo = deg_to_rad(95.0)   # Left range (derived from oscillation)
		a_hi = deg_to_rad(145.0)

	for s in range(REACH_SAMPLES):
		var frac := float(s) / float(REACH_SAMPLES - 1)
		var angle := a_lo + frac * (a_hi - a_lo)
		var vx := REACH_POWER * cos(angle)
		var vy := -REACH_POWER * sin(angle)  # Negative = upward

		# Solve: vy*t + 300*t² = -dy  →  300t² + vy*t + dy = 0
		var disc := vy * vy - 1200.0 * dy
		if disc < 0.0:
			continue

		var sd := sqrt(disc)
		# Two solutions: ascending hit (t1) and descending hit (t2)
		var t1 := (-vy - sd) / 600.0
		var t2 := (-vy + sd) / 600.0

		var times: Array[float] = [t1, t2]
		for t in times:
			if t > 0.02:
				var land_x: float = launch_x + vx * t
				if land_x >= tx and land_x <= tx + tw:
					return true

	return false


func _ensure_reachable(tx: float, tw: float, ty: float) -> float:
	"""If the platform at (tx, ty, tw) is unreachable from the previous one,
	nudge it horizontally toward the previous platform until it is reachable."""
	if _can_reach(_prev_x, _prev_w, _prev_y, tx, tw, ty):
		return tx

	var prev_cx := _prev_x + _prev_w * 0.5
	var cur_cx := tx + tw * 0.5
	var direction := -1.0 if cur_cx > prev_cx else 1.0  # Move toward prev

	for attempt in range(30):
		tx += direction * 8.0
		tx = clampf(tx, 5.0, VIEWPORT_WIDTH - tw - 5.0)
		if _can_reach(_prev_x, _prev_w, _prev_y, tx, tw, ty):
			return tx

	# Last resort: place directly above the previous platform's centre
	return clampf(prev_cx - tw * 0.5, 5.0, VIEWPORT_WIDTH - tw - 5.0)


func _create_platform(x: float, y: float, w: float, h: float, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x + w * 0.5, y + h * 0.5)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, h)
	col.shape = rect
	body.add_child(col)

	var visual := ColorRect.new()
	visual.size = Vector2(w, h)
	visual.position = Vector2(-w * 0.5, -h * 0.5)
	visual.color = color
	body.add_child(visual)

	add_child(body)


func _create_rest_walls(_plat_x: float, plat_y: float, _plat_w: float) -> void:
	# Visible bounce walls at the viewport edges near rest platforms.
	# They span from below the rest platform to slightly above it,
	# letting the player bounce off the walls and redirect onto the platform.
	var wall_w := 6.0
	var wall_h := 90.0
	var wall_top := plat_y - 10.0   # Slightly above the rest platform
	var wall_color := Color(0.40, 0.20, 0.60, 0.9)

	# Left wall at the left viewport edge
	_create_platform(0.0, wall_top, wall_w, wall_h, wall_color)
	# Right wall at the right viewport edge
	_create_platform(VIEWPORT_WIDTH - wall_w, wall_top, wall_w, wall_h, wall_color)


func _create_neon_drift_particles() -> void:
	var player := get_node_or_null("../Player")
	if player == null:
		return
	_cam = player.get_node_or_null("Camera2D")

	var drift := CPUParticles2D.new()
	drift.emitting = true
	drift.amount = NEON_DRIFT_AMOUNT
	drift.lifetime = 8.0
	drift.speed_scale = 0.5
	drift.explosiveness = 0.0
	drift.z_index = 5

	drift.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	drift.emission_rect_extents = Vector2(220, 15)

	drift.direction = Vector2(0, 1)
	drift.spread = 25.0
	drift.initial_velocity_min = 4.0
	drift.initial_velocity_max = 10.0
	drift.gravity = Vector2(2, 3)

	drift.scale_amount_min = 1.0
	drift.scale_amount_max = 2.5

	# Cyan and magenta neon drift
	drift.color = Color(0.0, 0.9, 1.0, 0.4)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.9, 0.2, 0.9, 0.5))
	grad.set_color(1, Color(0.0, 0.7, 0.9, 0.0))
	drift.color_ramp = grad

	add_child(drift)
	_neon_drift_particles = drift


func _create_digital_rain_particles() -> void:
	var rain := CPUParticles2D.new()
	rain.emitting = true
	rain.amount = DIGITAL_RAIN_AMOUNT
	rain.lifetime = 0.7
	rain.speed_scale = 1.0
	rain.explosiveness = 0.0
	rain.z_index = 5

	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(200, 5)

	# Straight down for "digital rain" look
	rain.direction = Vector2(0, 1)
	rain.spread = 2.0
	rain.initial_velocity_min = 180.0
	rain.initial_velocity_max = 280.0
	rain.gravity = Vector2(0, 80)

	rain.scale_amount_min = 0.8
	rain.scale_amount_max = 1.8

	# Bright cyan neon streaks
	rain.color = Color(0.0, 1.0, 1.0, 0.5)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.2, 1.0, 1.0, 0.6))
	grad.set_color(1, Color(0.0, 0.6, 0.7, 0.0))
	rain.color_ramp = grad

	add_child(rain)
	_digital_rain_particles = rain


func _update_particles() -> void:
	if _cam == null:
		var player := get_node_or_null("../Player")
		if player != null:
			_cam = player.get_node_or_null("Camera2D")
	if _cam == null:
		return
	var cam_pos := _cam.global_position
	var emit_y := cam_pos.y - 100
	if _digital_rain_particles != null:
		_digital_rain_particles.global_position = Vector2(cam_pos.x, emit_y)
	if _neon_drift_particles != null:
		_neon_drift_particles.global_position = Vector2(cam_pos.x, emit_y)


func _create_finish_label(finish_y: float) -> void:
	var label := Label.new()
	label.text = "GOAL"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0))
	label.position = Vector2(120, finish_y - 20)
	label.size = Vector2(80, 16)
	add_child(label)


func _create_beyond_label(finish_y: float) -> void:
	var label := Label.new()
	label.text = "~ ENDLESS ~"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.9, 0.85))
	label.position = Vector2(100, finish_y - 50)
	label.size = Vector2(120, 12)
	add_child(label)
