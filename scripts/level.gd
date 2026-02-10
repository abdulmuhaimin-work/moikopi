extends Node2D

# Vertical level: platforms zigzag upward.
# Platform data: [x, y_top, width, height]
# Viewport: 320x180. Player starts near y=160, finish near y=-2850.
var platforms: Array = [
	# === Starting ground ===
	[40, 160, 240, 20],
	# === Easy first jumps - zigzag up ===
	[180, 115, 50, 8],
	[60, 70, 50, 8],
	[190, 25, 50, 8],
	[50, -20, 50, 8],
	# === Section 2 - moderate gaps ===
	[185, -70, 45, 8],
	[40, -120, 45, 8],
	[195, -170, 45, 8],
	[55, -220, 45, 8],
	[180, -270, 45, 8],
	# === Rest platform ===
	[70, -325, 180, 8],
	# === Section 3 - narrower platforms ===
	[190, -380, 38, 8],
	[50, -430, 38, 8],
	[200, -480, 38, 8],
	[40, -530, 38, 8],
	[190, -585, 38, 8],
	[60, -640, 38, 8],
	# === Rest platform ===
	[80, -700, 160, 8],
	# === Section 4 - precision ===
	[200, -755, 28, 8],
	[55, -810, 28, 8],
	[210, -865, 28, 8],
	[45, -920, 28, 8],
	[195, -975, 28, 8],
	[60, -1030, 28, 8],
	[200, -1085, 28, 8],
	# === Rest platform ===
	[75, -1145, 170, 8],
	# === Section 5 - fast zigzag ===
	[195, -1195, 35, 8],
	[65, -1240, 35, 8],
	[200, -1285, 35, 8],
	[55, -1330, 35, 8],
	[195, -1375, 35, 8],
	[60, -1420, 35, 8],
	[200, -1465, 35, 8],
	[50, -1510, 35, 8],
	# === Rest platform ===
	[80, -1570, 160, 8],
	# === Section 6 - long jumps ===
	[210, -1640, 30, 8],
	[30, -1710, 30, 8],
	[220, -1780, 30, 8],
	[40, -1850, 30, 8],
	[210, -1920, 30, 8],
	# === Rest platform ===
	[70, -1985, 180, 8],
	# === Section 7 - tiny platforms ===
	[205, -2045, 22, 8],
	[50, -2100, 22, 8],
	[215, -2155, 22, 8],
	[40, -2210, 22, 8],
	[205, -2270, 22, 8],
	[55, -2330, 22, 8],
	# === Rest platform ===
	[85, -2395, 150, 8],
	# === Section 8 - final challenge ===
	[210, -2455, 25, 8],
	[40, -2515, 25, 8],
	[215, -2575, 25, 8],
	[35, -2640, 25, 8],
	[210, -2705, 25, 8],
	[50, -2770, 25, 8],
	[200, -2840, 28, 8],
	# === FINISH platform (gold) ===
	[50, -2910, 220, 12],
]

# Y position that triggers finish (top of finish platform)
const FINISH_Y := -2910.0

var platform_color := Color(0.35, 0.55, 0.35)
var platform_alt := Color(0.30, 0.50, 0.38)
var rest_color := Color(0.40, 0.55, 0.50)
var finish_color := Color(0.95, 0.80, 0.20)
var ground_color := Color(0.25, 0.38, 0.25)


const DEATH_Y := 220.0  # Below the starting platform


func _ready() -> void:
	# Tell GameManager where the finish and death lines are
	GameManager.finish_y = FINISH_Y
	GameManager.death_y = DEATH_Y

	for i in range(platforms.size()):
		var p: Array = platforms[i]
		var color: Color
		var is_last := (i == platforms.size() - 1)
		var is_first := (i == 0)
		var w: float = p[2]

		if is_last:
			color = finish_color
		elif is_first:
			color = ground_color
		elif w >= 100:
			color = rest_color  # Wide rest platforms
		elif i % 2 == 0:
			color = platform_color
		else:
			color = platform_alt

		_create_platform(p[0], p[1], p[2], p[3], color)

	# Add a "GOAL" label above the finish platform
	_create_finish_label()


func _create_platform(x: float, y: float, w: float, h: float, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x + w * 0.5, y + h * 0.5)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, h)
	col.shape = rect
	body.add_child(col)

	var visual := ColorRect.new()
	visual.size = Vector2(w, h)
	visual.position = Vector2(-w * 0.5, -h * 0.5)
	visual.color = color
	body.add_child(visual)

	add_child(body)


func _create_finish_label() -> void:
	var label := Label.new()
	label.text = "GOAL"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.95, 0.80, 0.20))
	label.position = Vector2(120, FINISH_Y - 20)
	label.size = Vector2(80, 16)
	add_child(label)
