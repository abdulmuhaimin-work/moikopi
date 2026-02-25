extends Area2D

## Place in a story level. When the player enters, a cutscene runs (text + duration).
## Set cutscene_text and display_duration in the inspector. One-shot (only fires once).

signal cutscene_triggered(text: String, duration: float)

@export var cutscene_text: String = "Welcome to the level."
@export var display_duration: float = 3.0

var _triggered: bool = false


func _ready() -> void:
	add_to_group("cutscene_trigger")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if not body.is_in_group("player"):
		return
	_triggered = true
	cutscene_triggered.emit(cutscene_text, display_duration)
