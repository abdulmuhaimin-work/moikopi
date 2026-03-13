extends Area2D

## Touching this opponent kills the player. When player is near (optional), shows dialogue.

signal near_dialogue_triggered(text: String)

@export var near_dialogue: String = ""
@export var near_distance: float = 70.0

var _near_shown: bool = false


func _ready() -> void:
	add_to_group("opponent")
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	if near_dialogue.is_empty() or _near_shown:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	if global_position.distance_to(player.global_position) < near_distance:
		_near_shown = true
		near_dialogue_triggered.emit(near_dialogue)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameManager.trigger_death(true)
