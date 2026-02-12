extends CharacterBody2D

enum State { IDLE, CHARGING, AIRBORNE }

# Physics
const GRAVITY := 600.0
const WALL_BOUNCE := 0.3

# Jump tuning
const MIN_POWER := 200.0
const MAX_POWER := 500.0
const CHARGE_RATE := 200.0
# Oscillation ranges per direction (from horizontal)
# Right: 45° (more sideways) to 85° (nearly vertical)
# Left:  95° (nearly vertical) to 135° (more sideways)
const ANGLE_RIGHT_MIN := deg_to_rad(35.0)
const ANGLE_RIGHT_MAX := deg_to_rad(85.0)
const ANGLE_LEFT_MIN := deg_to_rad(145.0)
const ANGLE_LEFT_MAX := deg_to_rad(195.0)
const ANGLE_SPEED := 3.5

# Visual
const ARROW_MIN_LEN := 15.0
const ARROW_MAX_LEN := 40.0

var state: State = State.IDLE
var charge_time: float = 0.0
var current_power: float = 0.0
var current_angle: float = 0.0
var charging_dir: int = 0  # -1 = left, 1 = right

# Input flags (set by _unhandled_input, consumed each physics frame)
var _jump_dir: int = 0      # -1 left, 1 right, 0 none (press)
var _jump_released := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var aim_arrow: Line2D = $AimArrow
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	aim_arrow.visible = false
	GameManager.start_y = global_position.y


func _unhandled_input(event: InputEvent) -> void:
	# Touch / mouse: left half = jump left, right half = jump right
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

	# Keyboard
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

	# Wall rebound
	if state == State.AIRBORNE:
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var normal := collision.get_normal()
			if abs(normal.x) > 0.7:
				velocity.x = -pre_velocity.x * WALL_BOUNCE
				GameManager.add_wall_bounce()
				break

	# Landing
	if state == State.AIRBORNE and is_on_floor():
		velocity = Vector2.ZERO
		state = State.IDLE
		GameManager.update_height(global_position.y)

	# Clear input flags
	_jump_dir = 0
	_jump_released = false


func _process_idle() -> void:
	aim_arrow.visible = false
	sprite.play("default")
	GameManager.is_charging = false
	GameManager.charge_percent = 0.0

	if GameManager.game_state == GameManager.GameState.FINISHED \
		or GameManager.game_state == GameManager.GameState.FAILED:
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

	# Oscillate angle within the chosen direction's half
	var t := charge_time * ANGLE_SPEED
	var osc := sin(t) * 0.5 + 0.5  # 0 to 1
	if charging_dir > 0:
		current_angle = ANGLE_RIGHT_MIN + osc * (ANGLE_RIGHT_MAX - ANGLE_RIGHT_MIN)
	else:
		current_angle = ANGLE_LEFT_MIN + osc * (ANGLE_LEFT_MIN - ANGLE_LEFT_MAX)

	var power_ratio := (current_power - MIN_POWER) / (MAX_POWER - MIN_POWER)

	# Aim arrow oscillates within the half, grows with power
	aim_arrow.visible = true
	var arrow_len := ARROW_MIN_LEN + power_ratio * (ARROW_MAX_LEN - ARROW_MIN_LEN)
	var dir := Vector2(cos(current_angle), -sin(current_angle))
	aim_arrow.points = PackedVector2Array([Vector2.ZERO, dir * arrow_len])
	aim_arrow.default_color = Color(
		1.0,
		1.0 - power_ratio * 0.7,
		0.3 - power_ratio * 0.3,
		0.9
	)

	GameManager.is_charging = true
	GameManager.charge_percent = power_ratio
	sprite.play("default")

	# Release to launch at current oscillating angle
	if _jump_released:
		velocity.x = current_power * cos(current_angle)
		velocity.y = -current_power * sin(current_angle)
		state = State.AIRBORNE
		GameManager.add_jump()
		aim_arrow.visible = false
		sprite.play("jump")
		GameManager.is_charging = false
		GameManager.charge_percent = 0.0


func _process_airborne() -> void:
	sprite.play("jump")
	GameManager.update_height(global_position.y)
