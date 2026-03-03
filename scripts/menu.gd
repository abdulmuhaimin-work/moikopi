extends Control


@onready var best_time_label: Label = $VBox/BestTimeLabel
@onready var controls_label: Label = $VBox/Controls
@onready var stats_label: Label = $VBox/StatsLabel
@onready var btn_endless: Button = $VBox/ModeButtons/BtnEndless
@onready var btn_story: Button = $VBox/ModeButtons/BtnStory
@onready var btn_endless_3d: Button = $VBox/ModeButtons/BtnEndless3D


func _ready() -> void:
	btn_endless.pressed.connect(_on_endless)
	btn_story.pressed.connect(_on_story)
	if btn_endless_3d != null:
		btn_endless_3d.pressed.connect(_on_endless_3d)
	# Records
	var parts: Array[String] = []
	if GameManager.best_height > 0.0:
		parts.append("Peak: %dm" % int(GameManager.best_height))
	if GameManager.best_finish_time >= 0.0:
		parts.append("Best: %s" % GameManager.get_time_string(GameManager.best_finish_time))
	best_time_label.text = "\n".join(parts)

	# Controls hint
	if DisplayServer.is_touchscreen_available():
		controls_label.text = "Tap = Endless | Left/Right = Jump"
	else:
		controls_label.text = "A/D or LB/RB = Jump | R/Y = Restart | Esc/Start = Menu"

	# Lifetime stats
	_update_stats()

	# Neon atmosphere on menu
	_create_menu_neon_particles()

	# Gamepad: give focus to the Endless button so D-pad/stick can navigate
	btn_endless.grab_focus()
	# Set focus neighbors so D-pad left/right moves between buttons
	if btn_endless_3d != null:
		btn_endless.focus_neighbor_right = btn_endless_3d.get_path()
		btn_endless_3d.focus_neighbor_left = btn_endless.get_path()
		btn_endless_3d.focus_neighbor_right = btn_story.get_path()
		btn_story.focus_neighbor_left = btn_endless_3d.get_path()
	else:
		btn_endless.focus_neighbor_right = btn_story.get_path()
		btn_story.focus_neighbor_left = btn_endless.get_path()


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
		_on_endless()
	elif event.is_action_pressed("jump_left") or event.is_action_pressed("jump_right"):
		_on_endless()
	elif event.is_action_pressed("gamepad_accept"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused == btn_story:
			_on_story()
		elif btn_endless_3d != null and focused == btn_endless_3d:
			_on_endless_3d()
		else:
			_on_endless()


func _on_endless() -> void:
	GameManager.start_endless()


func _on_endless_3d() -> void:
	GameManager.start_endless_3d()


func _on_story() -> void:
	GameManager.start_story(0)


func _create_menu_neon_particles() -> void:
	var rain := CPUParticles2D.new()
	rain.emitting = true
	rain.amount = 60
	rain.lifetime = 0.8
	rain.speed_scale = 1.0
	rain.explosiveness = 0.0
	rain.position = Vector2(160, -20)

	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(200, 5)

	rain.direction = Vector2(0, 1)
	rain.spread = 3.0
	rain.initial_velocity_min = 150.0
	rain.initial_velocity_max = 250.0
	rain.gravity = Vector2(0, 60)

	rain.scale_amount_min = 1.0
	rain.scale_amount_max = 2.0

	# Neon cyan digital rain
	rain.color = Color(0.0, 1.0, 1.0, 0.5)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.2, 1.0, 1.0, 0.6))
	grad.set_color(1, Color(0.0, 0.5, 0.6, 0.0))
	rain.color_ramp = grad

	add_child(rain)
