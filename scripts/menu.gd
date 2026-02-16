extends Control


@onready var best_time_label: Label = $VBox/BestTimeLabel
@onready var play_hint: Label = $VBox/PlayHint
@onready var controls_label: Label = $VBox/Controls
@onready var stats_label: Label = $VBox/StatsLabel


func _ready() -> void:
	# Records
	var parts: Array[String] = []
	if GameManager.best_height > 0.0:
		parts.append("Peak: %dm" % int(GameManager.best_height))
	if GameManager.best_finish_time >= 0.0:
		parts.append("Best: %s" % GameManager.get_time_string(GameManager.best_finish_time))
	best_time_label.text = "\n".join(parts)

	# Platform hints
	if DisplayServer.is_touchscreen_available():
		play_hint.text = "Tap to play"
		controls_label.text = "Left side = Jump left | Right side = Jump right"
	else:
		play_hint.text = "Press A/D to play"
		controls_label.text = "A / Left = Jump left | D / Right = Jump right"

	# Lifetime stats
	_update_stats()

	# Rain atmosphere on menu
	_create_menu_rain()
	AudioManager.play_rain()


func _update_stats() -> void:
	var s: Dictionary = GameManager.stats
	var runs: int = s["total_runs"]
	var finishes: int = s["total_finishes"]
	var falls: int = s["total_falls"]
	var finish_rate := "0%"
	if runs > 0:
		finish_rate = "%d%%" % int(float(finishes) / float(runs) * 100.0)
	var avg_height := "0m"
	if runs > 0:
		avg_height = "%dm" % int(s["total_height"] / float(runs))

	var lines: Array[String] = []
	lines.append("Jumps: %d    Runs: %d" % [s["total_jumps"], runs])
	lines.append("Finishes: %d    Falls: %d" % [finishes, falls])
	lines.append("Finish rate: %s    Avg height: %s" % [finish_rate, avg_height])
	lines.append("Total climbed: %dm    Bounces: %d" % [int(s["total_height"]), s["wall_bounces"]])
	lines.append("Play time: %s" % GameManager.get_play_time_string())
	stats_label.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_start_game()
	elif event.is_action_pressed("jump_left") or event.is_action_pressed("jump_right"):
		_start_game()


func _start_game() -> void:
	AudioManager.stop_rain()
	get_tree().change_scene_to_file(GameManager.GAME_SCENE)


func _create_menu_rain() -> void:
	var rain := CPUParticles2D.new()
	rain.emitting = true
	rain.amount = 80
	rain.lifetime = 0.7
	rain.speed_scale = 1.0
	rain.explosiveness = 0.0

	# Emission: wide rectangle above the viewport
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(200, 5)
	rain.position = Vector2(160, -10)

	# Movement: fast downward with slight wind
	rain.direction = Vector2(0.12, 1.0)
	rain.spread = 8.0
	rain.initial_velocity_min = 180.0
	rain.initial_velocity_max = 280.0
	rain.gravity = Vector2(8, 100)

	# Visible rain streaks (>= 1px for nearest-neighbor rendering)
	rain.scale_amount_min = 1.0
	rain.scale_amount_max = 2.0

	# Bright rain visible against dark menu background
	rain.color = Color(0.80, 0.85, 0.95, 0.55)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.85, 0.90, 1.0, 0.60))
	grad.set_color(1, Color(0.65, 0.70, 0.80, 0.10))
	rain.color_ramp = grad

	# Render on top of background and overlay (particles are translucent)
	add_child(rain)
