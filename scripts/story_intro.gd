extends Control

## Shown when entering Story mode. Displays the story hook; any key or tap continues to the first level.

@onready var hook_label: Label = $VBox/HookLabel
@onready var continue_label: Label = $VBox/ContinueLabel


func _ready() -> void:
	# Ensure we're in story mode and have a level to load
	if GameManager.current_story_level_path.is_empty():
		GameManager.current_story_level_path = GameManager.STORY_LEVELS[0]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		_go_to_first_level()


func _go_to_first_level() -> void:
	get_tree().change_scene_to_file(GameManager.current_story_level_path)
