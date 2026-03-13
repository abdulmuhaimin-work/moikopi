extends StaticBody2D

## Platform that stays solid for a duration, then fades and becomes non-solid. Resets when player leaves.

@export var platform_width: float = 80.0
@export var platform_height: float = 12.0
@export var platform_color: Color = Color(0.6, 0.2, 0.9, 0.85)
@export var hold_duration: float = 1.5
@export var reset_delay: float = 2.0

var _collision: CollisionShape2D = null
var _visual: ColorRect = null
var _timer: float = 0.0
var _active: bool = true
var _reset_timer: float = 0.0


func _ready() -> void:
	_build_collision()
	_build_visual()


func _build_collision() -> void:
	_collision = get_node_or_null("CollisionShape2D")
	if _collision == null:
		_collision = CollisionShape2D.new()
		_collision.name = "CollisionShape2D"
		add_child(_collision)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(platform_width, platform_height)
	_collision.shape = rect
	_collision.position = Vector2(-platform_width * 0.5, -platform_height * 0.5)


func _build_visual() -> void:
	_visual = get_node_or_null("ColorRect")
	if _visual == null:
		_visual = ColorRect.new()
		_visual.name = "ColorRect"
		add_child(_visual)
	_visual.size = Vector2(platform_width, platform_height)
	_visual.position = Vector2(-platform_width * 0.5, -platform_height * 0.5)
	_visual.color = platform_color


func _process(delta: float) -> void:
	if _active:
		_timer += delta
		if _timer >= hold_duration:
			_timer = 0.0
			_active = false
			_collision.set_deferred("disabled", true)
			_reset_timer = reset_delay
	else:
		_reset_timer -= delta
		_visual.modulate.a = move_toward(_visual.modulate.a, 0.15, delta * 2.0)
		if _reset_timer <= 0.0:
			_active = true
			_visual.modulate.a = 1.0
			_collision.set_deferred("disabled", false)
