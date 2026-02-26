extends Node2D

## Story level root. Two cutscene presentation styles:
##   AMBIENT   – translucent bar at screen bottom, text fades in, gameplay continues.
##   CINEMATIC – letterbox bars slide in, text types character-by-character, player frozen.

@export var camera_limit_left: float = -500.0
@export var camera_limit_top: float = -500.0
@export var camera_limit_right: float = 500.0
@export var camera_limit_bottom: float = 500.0
@export var death_y: float = 250.0
@export var level_index: int = 0
@export var next_level_path: String = ""

var _player: CharacterBody2D = null

# --- Overlay nodes (built at runtime) ---
var _overlay_layer: CanvasLayer = null
# Ambient
var _ambient_bar: ColorRect = null
var _ambient_label: Label = null
var _ambient_tween: Tween = null
# Cinematic
var _cine_top_bar: ColorRect = null
var _cine_bot_bar: ColorRect = null
var _cine_label: Label = null
var _cine_active: bool = false

const BAR_H := 24.0          # Letterbox bar height (viewport pixels)
const AMBIENT_BAR_H := 22.0  # Ambient bar height
const TYPE_SPEED := 0.04     # Seconds per character in cinematic mode
const FADE_TIME := 0.5       # Fade in/out duration


func _ready() -> void:
	GameManager.game_state = GameManager.GameState.RUNNING
	GameManager.elapsed_time = 0.0
	GameManager.max_height = 0.0
	GameManager.death_y = death_y
	GameManager.finish_y = -99999.0

	_spawn_player()
	_setup_goal()
	_build_overlay()
	_setup_cutscene_triggers()
	AudioManager.play_bgm()


# ---- Player & goal setup ----

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


# ---- Cutscene trigger wiring ----

func _setup_cutscene_triggers() -> void:
	for node in get_tree().get_nodes_in_group("cutscene_trigger"):
		if node.has_signal("cutscene_triggered"):
			node.cutscene_triggered.connect(_on_cutscene_triggered)


func _on_cutscene_triggered(text: String, duration: float, mode: int) -> void:
	if mode == 0:  # AMBIENT
		_show_ambient(text, duration)
	else:          # CINEMATIC
		_show_cinematic(text, duration)


# ---- Overlay construction ----

func _build_overlay() -> void:
	# Remove any editor-placed CutsceneOverlay so the old system doesn't conflict
	var old := get_node_or_null("CutsceneOverlay")
	if old != null:
		old.queue_free()

	_overlay_layer = CanvasLayer.new()
	_overlay_layer.name = "NarrativeOverlay"
	_overlay_layer.layer = 12
	add_child(_overlay_layer)

	_build_ambient_bar()
	_build_cinematic_bars()


func _build_ambient_bar() -> void:
	_ambient_bar = ColorRect.new()
	_ambient_bar.color = Color(0.0, 0.0, 0.0, 0.55)
	_ambient_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_ambient_bar.anchor_top = 1.0 - (AMBIENT_BAR_H / 180.0)
	_ambient_bar.anchor_bottom = 1.0
	_ambient_bar.offset_top = 0
	_ambient_bar.offset_bottom = 0
	_ambient_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ambient_bar.modulate.a = 0.0

	_ambient_label = Label.new()
	_ambient_label.name = "AmbientLabel"
	_ambient_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ambient_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ambient_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ambient_label.add_theme_font_size_override("font_size", 7)
	_ambient_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.9, 1.0))
	_ambient_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ambient_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ambient_bar.add_child(_ambient_label)
	_overlay_layer.add_child(_ambient_bar)


func _build_cinematic_bars() -> void:
	var bar_frac := BAR_H / 180.0

	_cine_top_bar = ColorRect.new()
	_cine_top_bar.color = Color(0.0, 0.0, 0.0, 1.0)
	_cine_top_bar.anchor_left = 0.0
	_cine_top_bar.anchor_right = 1.0
	_cine_top_bar.anchor_top = 0.0
	_cine_top_bar.anchor_bottom = 0.0
	_cine_top_bar.offset_bottom = 0
	_cine_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.add_child(_cine_top_bar)

	_cine_bot_bar = ColorRect.new()
	_cine_bot_bar.color = Color(0.0, 0.0, 0.0, 1.0)
	_cine_bot_bar.anchor_left = 0.0
	_cine_bot_bar.anchor_right = 1.0
	_cine_bot_bar.anchor_top = 1.0
	_cine_bot_bar.anchor_bottom = 1.0
	_cine_bot_bar.offset_top = 0
	_cine_bot_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.add_child(_cine_bot_bar)

	_cine_label = Label.new()
	_cine_label.name = "CineLabel"
	_cine_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cine_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cine_label.anchor_left = 0.1
	_cine_label.anchor_right = 0.9
	_cine_label.anchor_top = 1.0 - bar_frac - 0.02
	_cine_label.anchor_bottom = 1.0
	_cine_label.add_theme_font_size_override("font_size", 8)
	_cine_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1.0))
	_cine_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cine_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cine_label.modulate.a = 0.0
	_overlay_layer.add_child(_cine_label)


# ---- Ambient presentation ----

func _show_ambient(text: String, duration: float) -> void:
	if _ambient_tween != null and _ambient_tween.is_valid():
		_ambient_tween.kill()
	_ambient_label.text = text
	_ambient_tween = create_tween()
	_ambient_tween.tween_property(_ambient_bar, "modulate:a", 1.0, FADE_TIME)
	_ambient_tween.tween_interval(duration)
	_ambient_tween.tween_property(_ambient_bar, "modulate:a", 0.0, FADE_TIME)


# ---- Cinematic presentation ----

func _show_cinematic(text: String, duration: float) -> void:
	if _cine_active:
		return
	_cine_active = true

	# Freeze player
	if _player != null:
		_player.set_process_input(false)
		_player.set_physics_process(false)

	_cine_label.text = ""

	var bar_px := BAR_H

	# Slide letterbox bars in
	var tween_in := create_tween().set_parallel(true)
	tween_in.tween_property(_cine_top_bar, "offset_bottom", bar_px, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_in.tween_property(_cine_bot_bar, "offset_top", -bar_px, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween_in.finished

	# Typewriter effect
	_cine_label.modulate.a = 1.0
	for i in range(text.length()):
		_cine_label.text = text.substr(0, i + 1)
		await get_tree().create_timer(TYPE_SPEED).timeout

	# Hold for requested duration
	await get_tree().create_timer(duration).timeout

	# Fade text, slide bars out
	var tween_out := create_tween().set_parallel(true)
	tween_out.tween_property(_cine_label, "modulate:a", 0.0, 0.3)
	tween_out.tween_property(_cine_top_bar, "offset_bottom", 0.0, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween_out.tween_property(_cine_bot_bar, "offset_top", 0.0, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tween_out.finished

	# Unfreeze player
	if _player != null:
		_player.set_process_input(true)
		_player.set_physics_process(true)
	_cine_active = false
