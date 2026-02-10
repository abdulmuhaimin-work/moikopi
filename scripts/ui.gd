extends CanvasLayer

@onready var timer_label: Label = $TimerLabel
@onready var height_label: Label = $HeightLabel
@onready var best_label: Label = $BestTimeLabel
@onready var restart_hint: Label = $RestartHint
@onready var power_bar_bg: ColorRect = $PowerBarBg
@onready var power_bar_fill: ColorRect = $PowerBarBg/PowerBarFill
@onready var finish_panel: PanelContainer = $FinishPanel
@onready var finish_time_label: Label = $FinishPanel/VBox/FinishTimeLabel
@onready var finish_best_label: Label = $FinishPanel/VBox/FinishBestLabel
@onready var fail_panel: PanelContainer = $FailPanel
@onready var fail_height_label: Label = $FailPanel/VBox/FailHeightLabel
@onready var btn_restart: Button = $BtnRestart
@onready var btn_menu: Button = $BtnMenu
@onready var finish_btn_retry: Button = $FinishPanel/VBox/HBox/FinishBtnRetry
@onready var finish_btn_menu: Button = $FinishPanel/VBox/HBox/FinishBtnMenu
@onready var fail_btn_retry: Button = $FailPanel/VBox/HBox/FailBtnRetry
@onready var fail_btn_menu: Button = $FailPanel/VBox/HBox/FailBtnMenu

var _is_mobile := false


func _ready() -> void:
	finish_panel.visible = false
	fail_panel.visible = false
	_is_mobile = DisplayServer.is_touchscreen_available()

	btn_restart.pressed.connect(_on_restart)
	btn_menu.pressed.connect(_on_menu)
	finish_btn_retry.pressed.connect(_on_restart)
	finish_btn_menu.pressed.connect(_on_menu)
	fail_btn_retry.pressed.connect(_on_restart)
	fail_btn_menu.pressed.connect(_on_menu)

	if _is_mobile:
		restart_hint.text = "Left = jump left | Right = jump right"
	else:
		restart_hint.text = "A/D jump | R restart | Esc menu"


func _process(_delta: float) -> void:
	# Timer
	timer_label.text = GameManager.get_time_string()

	# Height
	var h := int(GameManager.max_height)
	height_label.text = "%dm" % h

	# Best finish time
	if GameManager.best_finish_time >= 0.0:
		best_label.text = "Best: %s" % GameManager.get_time_string(GameManager.best_finish_time)
	else:
		best_label.text = ""

	# Power bar
	power_bar_bg.visible = GameManager.is_charging
	if GameManager.is_charging:
		power_bar_fill.size.x = 60.0 * GameManager.charge_percent

	# Finish overlay
	if GameManager.game_state == GameManager.GameState.FINISHED and not finish_panel.visible:
		finish_panel.visible = true
		finish_time_label.text = GameManager.get_time_string()
		if GameManager.best_finish_time >= 0.0:
			finish_best_label.text = "Best: %s" % GameManager.get_time_string(GameManager.best_finish_time)
		else:
			finish_best_label.text = ""

	# Fail overlay
	if GameManager.game_state == GameManager.GameState.FAILED and not fail_panel.visible:
		fail_panel.visible = true
		fail_height_label.text = "Reached: %dm" % int(GameManager.max_height)


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		GameManager.restart()
	if Input.is_action_just_pressed("menu"):
		GameManager.go_to_menu()


func _on_restart() -> void:
	GameManager.restart()


func _on_menu() -> void:
	GameManager.go_to_menu()
