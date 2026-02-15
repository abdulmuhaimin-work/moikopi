extends CanvasLayer

@onready var timer_label: Label = $TimerLabel
@onready var height_label: Label = $HeightLabel
@onready var best_label: Label = $BestTimeLabel
@onready var restart_hint: Label = $RestartHint
@onready var power_bar_bg: ColorRect = $PowerBarBg
@onready var power_bar_fill: ColorRect = $PowerBarBg/PowerBarFill
@onready var goal_toast: Label = $GoalToast
@onready var fail_panel: PanelContainer = $FailPanel
@onready var fail_height_label: Label = $FailPanel/VBox/FailHeightLabel
@onready var btn_restart: Button = $BtnRestart
@onready var btn_menu: Button = $BtnMenu
@onready var fail_btn_retry: Button = $FailPanel/VBox/HBox/FailBtnRetry
@onready var fail_btn_menu: Button = $FailPanel/VBox/HBox/FailBtnMenu

var _is_mobile := false
var _toast_time_left: float = 0.0

const TOAST_DURATION := 3.5  # seconds the goal toast stays visible


func _ready() -> void:
	fail_panel.visible = false
	goal_toast.visible = false
	_is_mobile = DisplayServer.is_touchscreen_available()

	btn_restart.pressed.connect(_on_restart)
	btn_menu.pressed.connect(_on_menu)
	fail_btn_retry.pressed.connect(_on_restart)
	fail_btn_menu.pressed.connect(_on_menu)

	GameManager.goal_reached.connect(_on_goal_reached)

	if _is_mobile:
		restart_hint.text = "Left = jump left | Right = jump right"
	else:
		restart_hint.text = "A/D jump | R restart | Esc menu"


func _on_goal_reached(time_str: String) -> void:
	goal_toast.text = "GOAL!  %s" % time_str
	goal_toast.visible = true
	goal_toast.modulate.a = 1.0
	_toast_time_left = TOAST_DURATION
	AudioManager.play_goal()


func _process(delta: float) -> void:
	# Timer
	timer_label.text = GameManager.get_time_string()

	# Height
	var h := int(GameManager.max_height)
	height_label.text = "%dm" % h

	# Best records
	var parts: Array[String] = []
	if GameManager.best_height > 0.0:
		parts.append("Peak: %dm" % int(GameManager.best_height))
	if GameManager.best_finish_time >= 0.0:
		parts.append("Best: %s" % GameManager.get_time_string(GameManager.best_finish_time))
	best_label.text = " | ".join(parts)

	# Power bar
	power_bar_bg.visible = GameManager.is_charging
	if GameManager.is_charging:
		power_bar_fill.size.x = 60.0 * GameManager.charge_percent

	# Goal toast fade-out
	if _toast_time_left > 0.0:
		_toast_time_left -= delta
		if _toast_time_left <= 1.0:
			goal_toast.modulate.a = maxf(_toast_time_left, 0.0)
		if _toast_time_left <= 0.0:
			goal_toast.visible = false

	# Fail overlay
	if GameManager.game_state == GameManager.GameState.FAILED and not fail_panel.visible:
		fail_panel.visible = true
		fail_height_label.text = "Reached: %dm" % int(GameManager.max_height)
		AudioManager.play_fall()
		AudioManager.stop_bgm()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		GameManager.restart()
	if Input.is_action_just_pressed("menu"):
		GameManager.go_to_menu()


func _on_restart() -> void:
	GameManager.restart()


func _on_menu() -> void:
	GameManager.go_to_menu()
