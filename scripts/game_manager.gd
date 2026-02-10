extends Node

enum GameState { NOT_STARTED, RUNNING, FINISHED, FAILED }

var game_state: GameState = GameState.NOT_STARTED
var elapsed_time: float = 0.0
var start_y: float = 0.0
var finish_y: float = -99999.0  # Set by level
var death_y: float = 99999.0    # Set by level (below starting platform)
var max_height: float = 0.0
var best_finish_time: float = -1.0  # -1 = no record
var best_times: Dictionary = {}  # milestone -> best time

# Charge state (set by player, read by UI)
var charge_percent: float = 0.0
var is_charging: bool = false

const SAVE_PATH := "user://best_times.cfg"
const GAME_SCENE := "res://main.tscn"
const MENU_SCENE := "res://scenes/menu.tscn"


func _ready() -> void:
	load_best_times()


func _process(delta: float) -> void:
	if game_state == GameState.RUNNING:
		elapsed_time += delta


func start_run() -> void:
	game_state = GameState.RUNNING
	elapsed_time = 0.0


func update_height(player_y: float) -> void:
	var height := start_y - player_y  # Positive when going up
	if height > max_height:
		max_height = height
		var milestone := int(height / 500.0) * 500
		if milestone > 0:
			if not best_times.has(milestone) or elapsed_time < best_times[milestone]:
				best_times[milestone] = elapsed_time
				save_best_times()

	# Check finish
	if game_state == GameState.RUNNING and player_y <= finish_y:
		game_state = GameState.FINISHED
		if best_finish_time < 0.0 or elapsed_time < best_finish_time:
			best_finish_time = elapsed_time
			save_best_times()

	# Check death
	if game_state == GameState.RUNNING and player_y > death_y:
		game_state = GameState.FAILED


func restart() -> void:
	game_state = GameState.NOT_STARTED
	elapsed_time = 0.0
	max_height = 0.0
	charge_percent = 0.0
	is_charging = false
	get_tree().change_scene_to_file(GAME_SCENE)


func go_to_menu() -> void:
	game_state = GameState.NOT_STARTED
	elapsed_time = 0.0
	max_height = 0.0
	charge_percent = 0.0
	is_charging = false
	get_tree().change_scene_to_file(MENU_SCENE)


func get_time_string(time: float = -1.0) -> String:
	if time < 0.0:
		time = elapsed_time
	var minutes := int(time / 60.0)
	var seconds := int(time) % 60
	var millis := int(fmod(time, 1.0) * 1000.0)
	return "%02d:%02d.%03d" % [minutes, seconds, millis]


func load_best_times() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		for key in config.get_section_keys("times"):
			best_times[int(key)] = config.get_value("times", key)
		if config.has_section_key("finish", "best"):
			best_finish_time = config.get_value("finish", "best")


func save_best_times() -> void:
	var config := ConfigFile.new()
	for key in best_times:
		config.set_value("times", str(key), best_times[key])
	if best_finish_time >= 0.0:
		config.set_value("finish", "best", best_finish_time)
	config.save(SAVE_PATH)
