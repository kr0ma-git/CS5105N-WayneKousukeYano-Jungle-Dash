class_name EndlessGame
extends Node2D

## Root of the endless runner.
##
## The hero never moves sideways: the world (the chunks) slides left underneath
## them. This script owns the HUD, the pause menu and the game-over screen,
## keeps the layered jungle backdrop streaming past, and watches for the two
## ways a run can end instantly:
##   * the hero is swept too far left of the screen (death_x)
##   * the hero falls into a pit (kill_y)
## Hazards only cost a heart (see Player); losing the last heart ends the run
## too, through the player's died signal.

## The distant jungle image tiles horizontally at this width.
const BG_WIDTH = 2304.0
## The near canopy strip tiles horizontally at this (smaller) width.
const CANOPY_WIDTH = 1024.0
## Scene opened by every "main menu" button.
const MENU_SCENE := "res://scenes/main_menu.tscn"
## Seconds the control hint stays fully visible before it fades out.
const HINT_HOLD := 5.0

## Swept left of this world X ends the run.
@export var death_x: float = 40.0
## Below this world Y ends the run (pits).
@export var kill_y: float = 720.0
## The distant jungle scrolls at this fraction of the ground speed.
@export var bg_scroll_factor: float = 0.35
## The near canopy scrolls at this fraction of the ground speed.
@export var canopy_scroll_factor: float = 0.6

@onready var _player: Player = $Player
@onready var _spawner: ChunkSpawner = $Spawner
@onready var _background: Node2D = $Background
@onready var _canopy: Node2D = $Canopy
@onready var _hearts: HBoxContainer = $HUD/Root/HeartPanel/Hearts
@onready var _score: Label = $HUD/Root/ScoreBox/Score
@onready var _best: Label = $HUD/Root/ScoreBox/Best
@onready var _time: Label = $HUD/Root/ScoreBox/Timer
@onready var _hint: Label = $HUD/Root/Hint
@onready var _pause_panel: Control = $Overlay/PausePanel
@onready var _gameover_panel: Control = $Overlay/GameOverPanel
@onready var _final_score: Label = $Overlay/GameOverPanel/Center/Panel/VBox/FinalScore
@onready var _final_best: Label = $Overlay/GameOverPanel/Center/Panel/VBox/FinalBest
@onready var _music_slider: HSlider = $Overlay/PausePanel/Center/Panel/VBox/MusicRow/MusicSlider
@onready var _sfx_slider: HSlider = $Overlay/PausePanel/Center/Panel/VBox/SfxRow/SfxSlider

## False once the run has ended, so the world stops being policed.
var _running: bool = true
## Seconds since the run began, used to fade the hint out.
var _elapsed: float = 0.0
## Metres covered, remembered from the last frame the hero was alive.
var _distance: float = 0.0

func _ready() -> void:
	Audio.play_music(Audio.GAME_MUSIC)
	_player.died.connect(_on_player_died)
	_player.health_changed.connect(_on_health_changed)
	_update_hearts(_player.health)
	_best.text = "BEST  %d m" % int(Settings.best_distance)
	# Show whichever key the player has actually bound, so the accessibility
	# rebind is reflected in the hint instead of a hard-coded key name.
	_hint.text = "%s / W to jump  -  dodge the snakes, spikes and pits" % Settings.jump_key_label()
	_bind_overlay()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_elapsed += delta
	if _hint.modulate.a > 0.0 and _elapsed > HINT_HOLD:
		_hint.modulate.a = maxf(0.0, _hint.modulate.a - delta * 0.7)

	if not _running or not is_instance_valid(_player):
		return
	var pos: Vector2 = _player.global_position
	if pos.x < death_x or pos.y > kill_y:
		_player.die()
		return
	_distance = _spawner.distance / 32.0
	_score.text = "%d m" % int(_distance)
	var seconds: int = int(_elapsed)
	_time.text = "TIME  %d:%02d" % [int(seconds / 60.0), seconds % 60]

func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	# Slide the jungle layers left and wrap each once it has travelled its own
	# width, so the background never runs out no matter how far we get.
	_scroll_layer(_background, bg_scroll_factor, delta, BG_WIDTH)
	_scroll_layer(_canopy, canopy_scroll_factor, delta, CANOPY_WIDTH)

func _scroll_layer(layer: Node2D, factor: float, delta: float, wrap_width: float) -> void:
	layer.position.x -= _spawner.speed * delta * factor
	if layer.position.x <= -wrap_width:
		layer.position.x += wrap_width

func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()

## Wires every button and slider in the pause and game-over overlays.
func _bind_overlay() -> void:
	_wire("Overlay/PausePanel/Center/Panel/VBox/ResumeButton", _resume)
	_wire("Overlay/PausePanel/Center/Panel/VBox/RestartButton", _restart)
	_wire("Overlay/PausePanel/Center/Panel/VBox/MenuButton", _goto_menu)
	_wire("Overlay/GameOverPanel/Center/Panel/VBox/RetryButton", _restart)
	_wire("Overlay/GameOverPanel/Center/Panel/VBox/MenuButton", _goto_menu)

	_music_slider.value_changed.connect(_on_music_slider)
	_sfx_slider.value_changed.connect(_on_sfx_slider)
	_music_slider.value = Settings.music_volume * 100.0
	_sfx_slider.value = Settings.sfx_volume * 100.0

	_pause_panel.visible = false
	_gameover_panel.visible = false

## Hooks a button up to its action plus the shared hover and click sounds.
func _wire(path: String, action: Callable) -> void:
	var button: Button = get_node(path) as Button
	button.pressed.connect(action)
	button.mouse_entered.connect(_on_button_hover)
	button.pressed.connect(_on_button_click)

func _get_button(path: String) -> Button:
	return get_node(path) as Button

func _on_button_hover() -> void:
	Audio.play_sfx("ui_hover")

func _on_button_click() -> void:
	Audio.play_sfx("ui_select")

func _on_music_slider(value: float) -> void:
	Settings.set_music_volume(value / 100.0)

func _on_sfx_slider(value: float) -> void:
	Settings.set_sfx_volume(value / 100.0)

func _on_health_changed(health: int) -> void:
	_update_hearts(health)

## Shows one heart per remaining life and hides the spent ones.
func _update_hearts(health: int) -> void:
	var index: int = 0
	for heart in _hearts.get_children():
		heart.visible = index < health
		index += 1

func _on_player_died() -> void:
	_running = false
	# Freeze the world where it is: nothing should keep scrolling past the hero.
	get_tree().paused = true
	# A short beat so the player sees what ended the run, then the summary.
	await get_tree().create_timer(0.8).timeout
	var metres: int = int(_distance)
	Settings.set_best_distance(float(metres))
	_final_score.text = "DISTANCE   %d m" % metres
	_final_best.text = "BEST   %d m" % int(Settings.best_distance)
	_gameover_panel.visible = true
	_get_button("Overlay/GameOverPanel/Center/Panel/VBox/RetryButton").grab_focus()

func _pause() -> void:
	get_tree().paused = true
	_pause_panel.visible = true
	_get_button("Overlay/PausePanel/Center/Panel/VBox/ResumeButton").grab_focus()

func _resume() -> void:
	get_tree().paused = false
	_pause_panel.visible = false

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _goto_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)