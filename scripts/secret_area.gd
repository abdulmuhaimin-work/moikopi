extends Area2D

## When the player enters, shows optional message and triggers story_level secret_found.

signal secret_found(message: String)

@export var secret_message: String = "You found a hidden echo of the old network."
@export var one_shot: bool = true

var _triggered: bool = false


func _ready() -> void:
	add_to_group("secret_area")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if one_shot and _triggered:
		return
	_triggered = true
	secret_found.emit(secret_message)
