extends AnimatableBody2D

## Platform that moves between two points. Pushes the player when they stand on it.

@export var platform_width: float = 80.0
@export var platform_height: float = 12.0
@export var platform_color: Color = Color(0.25, 0.15, 0.45, 0.95)
@export var move_speed: float = 40.0
@export var offset_a: Vector2 = Vector2(0, 0)
@export var offset_b: Vector2 = Vector2(120, 0)

var _collision: CollisionShape2D = null
var _visual: ColorRect = null
var _start_pos: Vector2
var _t: float = 0.0
var _forward: bool = true


func _ready() -> void:
	_start_pos = global_position
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


func _physics_process(delta: float) -> void:
	var from := _start_pos + offset_a
	var to := _start_pos + offset_b
	var dist := (to - from).length()
	if dist < 1.0:
		return
	var step := (move_speed / dist) * delta
	_t += step
	if _t >= 1.0:
		_t = 0.0
		_forward = not _forward
	if _forward:
		global_position = from.lerp(to, clampf(_t, 0.0, 1.0))
	else:
		global_position = to.lerp(from, clampf(_t, 0.0, 1.0))
