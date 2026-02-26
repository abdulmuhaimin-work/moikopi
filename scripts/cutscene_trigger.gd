extends Area2D

## Triggers narrative text when the player enters.
## Two modes:
##   AMBIENT  – text fades in at the bottom of the screen, gameplay continues.
##   CINEMATIC – letterbox bars slide in, text types out, player is frozen.

enum Mode { AMBIENT, CINEMATIC }

signal cutscene_triggered(text: String, duration: float, mode: int)

@export var cutscene_text: String = ""
@export var display_duration: float = 4.0
@export var mode: Mode = Mode.AMBIENT

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
	cutscene_triggered.emit(cutscene_text, display_duration, mode)
