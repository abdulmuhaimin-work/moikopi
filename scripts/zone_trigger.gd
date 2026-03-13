extends Area2D

## When the player enters, notifies story level to switch zone (theme / music tint).

signal zone_entered(zone_id: int)

@export var zone_id: int = 0
@export var one_shot: bool = false

var _entered: bool = false


func _ready() -> void:
	add_to_group("zone_trigger")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if one_shot and _entered:
		return
	_entered = true
	zone_entered.emit(zone_id)
