extends Node2D

## Draws a simple ghost circle for the echo marker (child of EchoMarker Node2D).

func _draw() -> void:
	draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 24, Color(0.5, 0.9, 1.0, 0.6))
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 16, Color(0.7, 1.0, 1.0, 0.35))
