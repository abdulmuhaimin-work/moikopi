extends Area2D

## Touching this opponent kills the player (triggers fail state and restart).

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameManager.trigger_death(true)
