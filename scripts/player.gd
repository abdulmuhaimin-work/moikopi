extends CharacterBody2D

enum State { IDLE, CHARGING, AIRBORNE }

# Physics
const GRAVITY := 600.0
const WALL_BOUNCE := 0.3

# Jump tuning
const MIN_POWER := 200.0
const MAX_POWER := 500.0
const CHARGE_RATE := 200.0
const DOUBLE_JUMP_POWER := 280.0
const AIR_DASH_SPEED := 320.0
const AIR_DASH_DURATION := 0.12
# Oscillation ranges per direction (from horizontal)
const ANGLE_RIGHT_MIN := deg_to_rad(35.0)
const ANGLE_RIGHT_MAX := deg_to_rad(85.0)
const ANGLE_LEFT_MIN := deg_to_rad(145.0)
const ANGLE_LEFT_MAX := deg_to_rad(195.0)
const ANGLE_SPEED := 3.5

# Echo
const ECHO_DURATION := 4.0

# Visual
const ARROW_MIN_LEN := 15.0
const ARROW_MAX_LEN := 40.0

# Juice
const LAND_SHAKE_AMOUNT := 3.0
const LAND_SHAKE_DURATION := 0.15

var state: State = State.IDLE
var charge_time: float = 0.0
var current_power: float = 0.0
var current_angle: float = 0.0
var charging_dir: int = 0  # -1 = left, 1 = right

# Input flags (set by _unhandled_input, consumed each physics frame)
var _jump_dir: int = 0      # -1 left, 1 right, 0 none (press)
var _jump_released := false
var _echo_pressed := false
var _dash_pressed := false

# Abilities (per air time)
var _double_jump_used := false
var _dash_used_this_air := false
var _dash_timer: float = 0.0

# Echo
var _echo_pos: Vector2 = Vector2.ZERO
var _echo_time_left: float = 0.0
var _echo_placed := false
var _echo_marker: Node2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var aim_arrow: Line2D = $AimArrow
@onready var camera: Camera2D = $Camera2D
var land_particles: CPUParticles2D = null


func _ready() -> void:
	add_to_group("player")
	aim_arrow.visible = false
	GameManager.start_y = global_position.y
	land_particles = get_node_or_null("LandParticles")
	if land_particles:
		land_particles.emitting = false


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
	if event.is_action_pressed("echo"):
		_echo_pressed = true
	if event.is_action_pressed("air_dash"):
		_dash_pressed = true


func _physics_process(delta: float) -> void:
	# Air dash override (brief no-gravity)
	if _dash_timer > 0.0:
		_dash_timer -= delta
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Echo countdown and recall
	if _echo_placed:
		_echo_time_left -= delta
		if _echo_marker:
			_echo_marker.modulate.a = (_echo_time_left / ECHO_DURATION) * 0.8 + 0.2
		if _echo_time_left <= 0.0:
			_do_echo_recall()

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
				AudioManager.play_bounce()
				break

	# Landing
	if state == State.AIRBORNE and is_on_floor():
		velocity = Vector2.ZERO
		state = State.IDLE
		_double_jump_used = false
		_dash_used_this_air = false
		AudioManager.play_land()
		GameManager.update_height(global_position.y)
		_do_land_juice()

	# Clear input flags
	_jump_dir = 0
	_jump_released = false
	_echo_pressed = false
	_dash_pressed = false


func _process_idle() -> void:
	aim_arrow.visible = false
	sprite.play("default")
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
	aim_arrow.default_color = Color(power_ratio * 0.95, 0.15, 1.0, 0.95)

	GameManager.is_charging = true
	GameManager.charge_percent = power_ratio
	sprite.play("default")

	# Release to launch
	if _jump_released:
		velocity.x = current_power * cos(current_angle)
		velocity.y = -current_power * sin(current_angle)
		state = State.AIRBORNE
		GameManager.add_jump()
		AudioManager.play_jump()
		aim_arrow.visible = false
		sprite.play("jump")
		GameManager.is_charging = false
		GameManager.charge_percent = 0.0


func _process_airborne() -> void:
	# Double jump (Story ability) — press direction again in air
	if GameManager.story_ability_double_jump and not _double_jump_used and _jump_dir != 0:
		var dj_dir: int = _jump_dir
		velocity.x = DOUBLE_JUMP_POWER * 0.6 * (1.0 if dj_dir > 0 else -1.0)
		velocity.y = -DOUBLE_JUMP_POWER * 0.75
		_double_jump_used = true
		GameManager.add_jump()
		AudioManager.play_jump()
		return

	# Air dash (Story ability)
	if GameManager.story_ability_air_dash and _dash_pressed and not _dash_used_this_air:
		var dash_dir: int = 1 if velocity.x >= 0 else -1
		if _jump_dir != 0:
			dash_dir = _jump_dir
		velocity.x = AIR_DASH_SPEED * dash_dir
		velocity.y = 0.0
		_dash_timer = AIR_DASH_DURATION
		_dash_used_this_air = true
		AudioManager.play_dash()
		return

	# Place echo
	if _echo_pressed and not _echo_placed and GameManager.game_state == GameManager.GameState.RUNNING:
		_echo_pos = global_position
		_echo_placed = true
		_echo_time_left = ECHO_DURATION
		_spawn_echo_marker()
		AudioManager.play_echo_place()
		return

	sprite.play("jump")
	GameManager.update_height(global_position.y)


func _spawn_echo_marker() -> void:
	if _echo_marker:
		_echo_marker.queue_free()
	_echo_marker = Node2D.new()
	_echo_marker.name = "EchoMarker"
	_echo_marker.z_index = 10
	_echo_marker.global_position = _echo_pos
	get_parent().add_child(_echo_marker)
	# Draw a simple ghost shape (circle via script)
	var draw_node = Node2D.new()
	draw_node.set_script(load("res://scripts/echo_marker_draw.gd"))
	_echo_marker.add_child(draw_node)


func _do_echo_recall() -> void:
	global_position = _echo_pos
	velocity = Vector2.ZERO
	_echo_placed = false
	_double_jump_used = false
	_dash_used_this_air = false
	if _echo_marker:
		_echo_marker.queue_free()
		_echo_marker = null
	AudioManager.play_echo_recall()


func _do_land_juice() -> void:
	# Screen shake
	if camera:
		var tw := create_tween()
		tw.tween_property(camera, "offset", Vector2(LAND_SHAKE_AMOUNT, 0), LAND_SHAKE_DURATION * 0.25).set_ease(Tween.EASE_OUT)
		tw.tween_property(camera, "offset", Vector2(-LAND_SHAKE_AMOUNT * 0.8, 0), LAND_SHAKE_DURATION * 0.25)
		tw.tween_property(camera, "offset", Vector2(LAND_SHAKE_AMOUNT * 0.4, 0), LAND_SHAKE_DURATION * 0.25)
		tw.tween_property(camera, "offset", Vector2.ZERO, LAND_SHAKE_DURATION * 0.25)
	# Particles
	if land_particles:
		land_particles.global_position = global_position
		land_particles.emitting = true
