extends Node

## Centralised audio playback: BGM loop + pooled SFX players.

# --- Preloaded streams ---
var _bgm_stream: AudioStream = preload("res://assets/audio/bgm.wav")
var _sfx_jump: AudioStream   = preload("res://assets/audio/jump.wav")
var _sfx_land: AudioStream   = preload("res://assets/audio/land.wav")
var _sfx_bounce: AudioStream = preload("res://assets/audio/bounce.wav")
var _sfx_goal: AudioStream   = preload("res://assets/audio/goal.wav")
var _sfx_fall: AudioStream   = preload("res://assets/audio/fall.wav")

# --- Internal players ---
var _bgm: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 6

# Rain ambience (loaded at runtime)
var _rain_stream: AudioStream = null


func _ready() -> void:
	# BGM player
	_bgm = AudioStreamPlayer.new()
	_bgm.volume_db = -8.0
	add_child(_bgm)
	_bgm.finished.connect(_on_bgm_finished)

	# Rain ambience player
	_rain = AudioStreamPlayer.new()
	_rain.volume_db = -6.0
	add_child(_rain)
	_rain.finished.connect(_on_rain_finished)
	_rain_stream = load("res://assets/audio/rain_ambience.wav")

	# SFX pool
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)


# --- Private helpers ---

func _play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return
	# All busy — steal the first slot
	_sfx_pool[0].stop()
	_sfx_pool[0].stream = stream
	_sfx_pool[0].volume_db = volume_db
	_sfx_pool[0].play()


func _on_bgm_finished() -> void:
	_bgm.play()  # Seamless loop


func _on_rain_finished() -> void:
	if _rain.volume_db > -40.0:
		_rain.play()  # Loop while audible


# --- Public API ---

func play_jump() -> void:
	_play_sfx(_sfx_jump, -4.0)


func play_land() -> void:
	_play_sfx(_sfx_land, -6.0)


func play_bounce() -> void:
	_play_sfx(_sfx_bounce, -5.0)


func play_goal() -> void:
	_play_sfx(_sfx_goal, 0.0)


func play_fall() -> void:
	_play_sfx(_sfx_fall, -3.0)


func play_bgm() -> void:
	if not _bgm.playing:
		_bgm.stream = _bgm_stream
		_bgm.play()


func stop_bgm() -> void:
	_bgm.stop()


func play_rain() -> void:
	if _rain_stream and not _rain.playing:
		_rain.stream = _rain_stream
		_rain.play()


func stop_rain() -> void:
	_rain.stop()


func set_rain_volume(factor: float) -> void:
	if factor < 0.01:
		if _rain.playing:
			_rain.stop()
		return
	if _rain_stream and not _rain.playing:
		_rain.stream = _rain_stream
		_rain.play()
	_rain.volume_db = lerpf(-35.0, -6.0, factor)
