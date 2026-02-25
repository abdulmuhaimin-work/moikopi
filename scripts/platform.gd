extends StaticBody2D

## Editor-friendly platform for Story mode. Set width, height, and color in the inspector.
## Position this node at the *center* of where you want the platform.

@export var platform_width: float = 80.0
@export var platform_height: float = 12.0
@export var platform_color: Color = Color(0.0, 0.75, 0.85, 0.9)


func _ready() -> void:
	_build_collision()
	_build_visual()


func _build_collision() -> void:
	var col: CollisionShape2D = get_node_or_null("CollisionShape2D")
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)
	# Use a new shape per instance so all platforms don't share one (shared SubResource
	# would get overwritten by the last _ready(), making every platform the same size).
	var rect := RectangleShape2D.new()
	rect.size = Vector2(platform_width, platform_height)
	col.shape = rect


func _build_visual() -> void:
	var visual: ColorRect = get_node_or_null("ColorRect")
	if visual == null:
		visual = ColorRect.new()
		visual.name = "ColorRect"
		add_child(visual)
	visual.size = Vector2(platform_width, platform_height)
	visual.position = Vector2(-platform_width * 0.5, -platform_height * 0.5)
	visual.color = platform_color
