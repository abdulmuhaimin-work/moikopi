extends Area2D

## When the player enters, triggers a brief screen glitch (story_level handles the effect).

signal glitch_triggered

@export var one_shot: bool = true

var _triggered: bool = false


func _ready() -> void:
	add_to_group("glitch_trigger")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if one_shot and _triggered:
		return
	_triggered = true
	glitch_triggered.emit()
