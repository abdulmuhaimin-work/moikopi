extends Node2D

## Story level root. Expects these children (add in editor):
## - PlayerStart (Marker2D): where the player spawns
## - Goal (Area2D): when player enters, level completes
## - Platforms (Node2D): add Platform instances here for platforms
## - CutsceneOverlay: CanvasLayer with Panel + Label (optional; created at runtime if missing)
##
## Optional: set camera_limit_* exports to constrain the camera.

@export var camera_limit_left: float = -500.0
@export var camera_limit_top: float = -500.0
@export var camera_limit_right: float = 500.0
@export var camera_limit_bottom: float = 500.0
@export var death_y: float = 250.0  # Player dies if they fall below this Y
@export var level_index: int = 0
@export var next_level_path: String = ""  # If empty, return to menu on complete

var _player: CharacterBody2D = null
var _cutscene_overlay: CanvasLayer = null
var _cutscene_label: Label = null


func _ready() -> void:
	GameManager.game_state = GameManager.GameState.RUNNING
	GameManager.elapsed_time = 0.0
	GameManager.max_height = 0.0
	GameManager.death_y = death_y
	GameManager.finish_y = -99999.0  # No height-based finish in story

	_spawn_player()
	_setup_goal()
	_setup_cutscene_triggers()
	_build_cutscene_overlay_if_needed()
	AudioManager.play_bgm()


func _spawn_player() -> void:
	var start: Node2D = get_node_or_null("PlayerStart")
	if start == null:
		push_error("StoryLevel: No PlayerStart node found.")
		return
	var player_scene := load(GameManager.PLAYER_SCENE) as PackedScene
	if player_scene == null:
		push_error("StoryLevel: Could not load player scene.")
		return
	_player = player_scene.instantiate() as CharacterBody2D
	_player.global_position = start.global_position
	add_child(_player)
	GameManager.start_y = _player.global_position.y

	var cam: Camera2D = _player.get_node_or_null("Camera2D")
	if cam != null:
		cam.limit_left = int(camera_limit_left)
		cam.limit_top = int(camera_limit_top)
		cam.limit_right = int(camera_limit_right)
		cam.limit_bottom = int(camera_limit_bottom)


func _setup_goal() -> void:
	var goal: Area2D = get_node_or_null("Goal")
	if goal == null:
		return
	goal.body_entered.connect(_on_goal_entered)


func _on_goal_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameManager.goal_reached.emit(GameManager.get_time_string())
	AudioManager.play_goal()
	if next_level_path.is_empty():
		await get_tree().create_timer(1.5).timeout
		GameManager.go_to_menu()
	else:
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file(next_level_path)


func _setup_cutscene_triggers() -> void:
	for node in get_tree().get_nodes_in_group("cutscene_trigger"):
		if node.has_signal("cutscene_triggered"):
			node.cutscene_triggered.connect(_on_cutscene_triggered)


func _build_cutscene_overlay_if_needed() -> void:
	_cutscene_overlay = get_node_or_null("CutsceneOverlay")
	if _cutscene_overlay != null:
		_cutscene_label = _cutscene_overlay.get_node_or_null("Panel/MarginContainer/Label")
		if _cutscene_label == null:
			_cutscene_label = _cutscene_overlay.get_node_or_null("Label")
		if _cutscene_label != null:
			_cutscene_overlay.visible = false
		return
	# Create minimal overlay at runtime
	var layer := CanvasLayer.new()
	layer.name = "CutsceneOverlay"
	layer.layer = 10
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	var label := Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.text = ""
	margin.add_child(label)
	panel.add_child(margin)
	layer.add_child(panel)
	add_child(layer)
	_cutscene_overlay = layer
	_cutscene_label = label
	_cutscene_overlay.visible = false


func _on_cutscene_triggered(text: String, duration: float) -> void:
	if _cutscene_label == null:
		return
	_cutscene_label.text = text
	_cutscene_overlay.visible = true
	_player.set_process_input(false)
	_player.set_physics_process(false)
	await get_tree().create_timer(duration).timeout
	_cutscene_overlay.visible = false
	_player.set_process_input(true)
	_player.set_physics_process(true)
