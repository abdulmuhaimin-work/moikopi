extends Control


@onready var best_time_label: Label = $VBox/BestTimeLabel
@onready var play_hint: Label = $VBox/PlayHint
@onready var controls_label: Label = $VBox/Controls


func _ready() -> void:
	if GameManager.best_finish_time >= 0.0:
		best_time_label.text = "Best: %s" % GameManager.get_time_string(GameManager.best_finish_time)
	else:
		best_time_label.text = ""

	if DisplayServer.is_touchscreen_available():
		play_hint.text = "Tap to play"
		controls_label.text = "Left side = Jump left | Right side = Jump right"
	else:
		play_hint.text = "Press A/D to play"
		controls_label.text = "A / Left = Jump left | D / Right = Jump right"


func _unhandled_input(event: InputEvent) -> void:
	# Any touch/click or jump key starts the game
	if event is InputEventMouseButton and event.pressed:
		_start_game()
	elif event.is_action_pressed("jump_left") or event.is_action_pressed("jump_right"):
		_start_game()


func _start_game() -> void:
	get_tree().change_scene_to_file(GameManager.GAME_SCENE)
