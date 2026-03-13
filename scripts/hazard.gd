extends Area2D

## Kills the player on contact (e.g. spikes, glitch zone).

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = Vector2(64, 24)
		shape.shape = rect
		shape.position = Vector2(-32, -12)
		add_child(shape)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameManager.trigger_death(false)
