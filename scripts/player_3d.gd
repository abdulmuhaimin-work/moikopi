extends CharacterBody3D

## 3D version of the charge-jump player. Movement in X (left/right) and Y (up).
## GameManager height uses effective Y = -global_position.y so same logic as 2D.

enum State { IDLE, CHARGING, AIRBORNE }

# Physics (Y is up in Godot 3D). Scale ~10x smaller than 2D for level units.
const GRAVITY := -60.0  # negative Y
const WALL_BOUNCE := 0.3

# Jump tuning (angles in X-Y plane: X = horizontal, Y = up)
const MIN_POWER := 20.0
const MAX_POWER := 50.0
const CHARGE_RATE := 20.0
const ANGLE_RIGHT_MIN := deg_to_rad(35.0)
const ANGLE_RIGHT_MAX := deg_to_rad(85.0)
const ANGLE_LEFT_MIN := deg_to_rad(145.0)
const ANGLE_LEFT_MAX := deg_to_rad(195.0)
const ANGLE_SPEED := 3.5

# Aim arrow (in X-Y plane, drawn in 3D)
const ARROW_MIN_LEN := 1.5
const ARROW_MAX_LEN := 4.0

var state: State = State.IDLE
var charge_time: float = 0.0
var current_power: float = 0.0
var current_angle: float = 0.0
var charging_dir: int = 0  # -1 = left, 1 = right

var _jump_dir: int = 0
var _jump_released := false

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var aim_arrow: MeshInstance3D = $AimArrow
@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	add_to_group("player")
	aim_arrow.visible = false
	# Neon-style material for player body
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.9, 0.95, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.6, 0.7, 1.0)
	mesh.material_override = mat
	# Effective Y for GameManager (same convention as 2D: higher value = higher)
	GameManager.start_y = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var vp_width := get_viewport().get_visible_rect().size.x
			if event.position.x < vp_width * 0.5:
				_jump_dir = -1
			else:
				_jump_dir = 1
		else:
			_jump_released = true
		return

	if event.is_action_pressed("jump_left"):
		_jump_dir = -1
	elif event.is_action_pressed("jump_right"):
		_jump_dir = 1
	elif event.is_action_released("jump_left") or event.is_action_released("jump_right"):
		_jump_released = true


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	match state:
		State.IDLE:
			_process_idle()
		State.CHARGING:
			_process_charging(delta)
		State.AIRBORNE:
			_process_airborne()

	var pre_velocity := velocity
	move_and_slide()

	# Wall rebound (X walls)
	if state == State.AIRBORNE:
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var normal := collision.get_normal()
			if abs(normal.x) > 0.7:
				velocity.x = -pre_velocity.x * WALL_BOUNCE
				GameManager.add_wall_bounce()
				AudioManager.play_bounce()
				break

	if state == State.AIRBORNE and is_on_floor():
		velocity = Vector3.ZERO
		state = State.IDLE
		AudioManager.play_land()
		GameManager.update_height(-global_position.y)

	_jump_dir = 0
	_jump_released = false


func _process_idle() -> void:
	aim_arrow.visible = false
	GameManager.is_charging = false
	GameManager.charge_percent = 0.0

	if GameManager.game_state == GameManager.GameState.FAILED:
		return

	if is_on_floor() and _jump_dir != 0:
		state = State.CHARGING
		charging_dir = _jump_dir
		charge_time = 0.0
		current_power = MIN_POWER
		if GameManager.game_state == GameManager.GameState.NOT_STARTED:
			GameManager.start_run()


func _process_charging(delta: float) -> void:
	charge_time += delta
	current_power = min(current_power + CHARGE_RATE * delta, MAX_POWER)

	var t := charge_time * ANGLE_SPEED
	var osc := sin(t) * 0.5 + 0.5
	if charging_dir > 0:
		current_angle = ANGLE_RIGHT_MIN + osc * (ANGLE_RIGHT_MAX - ANGLE_RIGHT_MIN)
	else:
		current_angle = ANGLE_LEFT_MIN + osc * (ANGLE_LEFT_MIN - ANGLE_LEFT_MAX)

	var power_ratio := (current_power - MIN_POWER) / (MAX_POWER - MIN_POWER)

	# Update aim arrow mesh (arrow along X-Y in local space: right=+X, up=+Y)
	aim_arrow.visible = true
	var arrow_len := ARROW_MIN_LEN + power_ratio * (ARROW_MAX_LEN - ARROW_MIN_LEN)
	var dir_x := cos(current_angle)
	var dir_y := sin(current_angle)
	_update_aim_arrow(arrow_len, Vector2(dir_x, dir_y), power_ratio)

	GameManager.is_charging = true
	GameManager.charge_percent = power_ratio

	if _jump_released:
		# Launch in X-Y plane (Z stays 0)
		velocity.x = current_power * cos(current_angle)
		velocity.y = current_power * sin(current_angle)
		velocity.z = 0.0
		state = State.AIRBORNE
		GameManager.add_jump()
		AudioManager.play_jump()
		aim_arrow.visible = false
		GameManager.is_charging = false
		GameManager.charge_percent = 0.0


func _update_aim_arrow(length: float, dir_xy: Vector2, power_ratio: float) -> void:
	# AimArrow: scale and rotate to point in dir_xy (X,Y plane)
	var arrow := aim_arrow
	arrow.scale = Vector3(length * 0.5, 0.15, 0.15)
	var angle := atan2(dir_xy.y, dir_xy.x)
	arrow.rotation.z = -angle
	arrow.position = Vector3(dir_xy.x * length * 0.5, dir_xy.y * length * 0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(power_ratio * 0.95, 0.15, 1.0, 0.95)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	arrow.material_override = mat


func _process_airborne() -> void:
	GameManager.update_height(-global_position.y)


func _process(_delta: float) -> void:
	# Camera follows and looks at player (slightly above feet)
	camera.look_at(global_position + Vector3(0, 1.0, 0), Vector3.UP)
