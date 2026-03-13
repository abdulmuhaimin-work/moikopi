extends Area2D

## Environmental story: when player enters, show terminal-style text (one-shot).

signal terminal_read(text: String, duration: float)

@export var terminal_text: String = "ERROR: Memory corrupted."
@export var display_duration: float = 3.5
@export var one_shot: bool = true

var _triggered: bool = false


func _ready() -> void:
	add_to_group("terminal")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if one_shot and _triggered:
		return
	_triggered = true
	terminal_read.emit(terminal_text, display_duration)
