extends Node

signal goal_reached(time_str: String)

enum GameMode { ENDLESS, STORY }
enum GameState { NOT_STARTED, RUNNING, ENDLESS, FAILED }

var game_mode: GameMode = GameMode.ENDLESS
var current_story_level_path: String = ""  # Set when entering story mode

var game_state: GameState = GameState.NOT_STARTED
var elapsed_time: float = 0.0
var start_y: float = 0.0
var finish_y: float = -99999.0  # Set by level
var death_y: float = 99999.0    # Set by level (below starting platform)
var max_height: float = 0.0
var best_finish_time: float = -1.0  # -1 = no record
var best_height: float = 0.0       # highest point ever reached
var best_times: Dictionary = {}    # milestone -> best time

# Charge state (set by player, read by UI)
var charge_percent: float = 0.0
var is_charging: bool = false

# Lifetime stats
var stats := {
	"total_jumps": 0,
	"total_runs": 0,
	"total_finishes": 0,
	"total_falls": 0,
	"total_height": 0.0,    # cumulative meters climbed
	"total_play_time": 0.0, # cumulative seconds in runs
	"wall_bounces": 0,
}

const SAVE_PATH := "user://best_times.cfg"
const GAME_SCENE := "res://main.tscn"
const MENU_SCENE := "res://scenes/menu.tscn"
const PLAYER_SCENE := "res://scenes/player.tscn"
const STORY_LEVELS := [
	"res://scenes/story/level_01.tscn",
]


func _ready() -> void:
	load_data()


func _process(delta: float) -> void:
	if game_state == GameState.RUNNING or game_state == GameState.ENDLESS:
		elapsed_time += delta
		stats["total_play_time"] += delta


func start_run() -> void:
	game_state = GameState.RUNNING
	elapsed_time = 0.0
	stats["total_runs"] += 1
	save_data()


func add_jump() -> void:
	stats["total_jumps"] += 1


func add_wall_bounce() -> void:
	stats["wall_bounces"] += 1


func update_height(player_y: float) -> void:
	var height := start_y - player_y  # Positive when going up
	if height > max_height:
		max_height = height
		if max_height > best_height:
			best_height = max_height
			save_data()
		var milestone := int(height / 500.0) * 500
		if milestone > 0:
			if not best_times.has(milestone) or elapsed_time < best_times[milestone]:
				best_times[milestone] = elapsed_time
				save_data()

	# Check finish (first time crossing the goal – transition to ENDLESS)
	if game_state == GameState.RUNNING and player_y <= finish_y:
		game_state = GameState.ENDLESS
		stats["total_finishes"] += 1
		if best_finish_time < 0.0 or elapsed_time < best_finish_time:
			best_finish_time = elapsed_time
		save_data()
		goal_reached.emit(get_time_string())

	# Check death (applies in both RUNNING and ENDLESS)
	if (game_state == GameState.RUNNING or game_state == GameState.ENDLESS) and player_y > death_y:
		game_state = GameState.FAILED
		stats["total_falls"] += 1
		stats["total_height"] += max_height
		save_data()


func restart() -> void:
	# Accumulate height from ongoing run (RUNNING or ENDLESS)
	if game_state == GameState.RUNNING or game_state == GameState.ENDLESS:
		stats["total_height"] += max_height
		save_data()
	game_state = GameState.NOT_STARTED
	elapsed_time = 0.0
	max_height = 0.0
	charge_percent = 0.0
	is_charging = false
	if game_mode == GameMode.STORY and current_story_level_path != "":
		get_tree().change_scene_to_file(current_story_level_path)
	else:
		get_tree().change_scene_to_file(GAME_SCENE)


func go_to_menu() -> void:
	if game_state == GameState.RUNNING or game_state == GameState.ENDLESS:
		stats["total_height"] += max_height
		save_data()
	AudioManager.stop_bgm()
	AudioManager.stop_rain()
	game_state = GameState.NOT_STARTED
	game_mode = GameMode.ENDLESS
	current_story_level_path = ""
	elapsed_time = 0.0
	max_height = 0.0
	charge_percent = 0.0
	is_charging = false
	get_tree().change_scene_to_file(MENU_SCENE)


func start_endless() -> void:
	game_mode = GameMode.ENDLESS
	get_tree().change_scene_to_file(GAME_SCENE)


func start_story(level_index: int = 0) -> void:
	game_mode = GameMode.STORY
	if level_index < 0 or level_index >= STORY_LEVELS.size():
		return
	current_story_level_path = STORY_LEVELS[level_index]
	get_tree().change_scene_to_file(current_story_level_path)


func get_time_string(time: float = -1.0) -> String:
	if time < 0.0:
		time = elapsed_time
	var minutes := int(time / 60.0)
	var seconds := int(time) % 60
	var millis := int(fmod(time, 1.0) * 1000.0)
	return "%02d:%02d.%03d" % [minutes, seconds, millis]


func get_play_time_string() -> String:
	var t: float = stats["total_play_time"]
	var hours := int(t / 3600.0)
	var minutes := int(t / 60.0) % 60
	var seconds := int(t) % 60
	if hours > 0:
		return "%dh %02dm %02ds" % [hours, minutes, seconds]
	elif minutes > 0:
		return "%dm %02ds" % [minutes, seconds]
	else:
		return "%ds" % seconds


func load_data() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		for key in config.get_section_keys("times"):
			best_times[int(key)] = config.get_value("times", key)
		if config.has_section_key("finish", "best"):
			best_finish_time = config.get_value("finish", "best")
		if config.has_section_key("records", "best_height"):
			best_height = config.get_value("records", "best_height")
		if config.has_section("stats"):
			for key in config.get_section_keys("stats"):
				if stats.has(key):
					stats[key] = config.get_value("stats", key)


func save_data() -> void:
	var config := ConfigFile.new()
	for key in best_times:
		config.set_value("times", str(key), best_times[key])
	if best_finish_time >= 0.0:
		config.set_value("finish", "best", best_finish_time)
	if best_height > 0.0:
		config.set_value("records", "best_height", best_height)
	for key in stats:
		config.set_value("stats", key, stats[key])
	config.save(SAVE_PATH)
