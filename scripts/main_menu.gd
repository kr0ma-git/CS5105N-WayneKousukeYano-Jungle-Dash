extends Control

## Title screen: Play / Settings / Quit.
##
## The Settings panel holds the two volume sliders (wired to the Music and SFX
## buses) and the accessible rebind control for the jump key - click "Change",
## then press any key.

const GAME_SCENE := "res://scenes/endless_runner.tscn"

@onready var _buttons: CenterContainer = $Center
@onready var _play_button: Button = $Center/Buttons/PlayButton
@onready var _settings_button: Button = $Center/Buttons/SettingsButton
@onready var _quit_button: Button = $Center/Buttons/QuitButton

@onready var _settings_center: CenterContainer = $CenterSettings
@onready var _music_slider: HSlider = $CenterSettings/SettingsPanel/VBox/MusicRow/MusicSlider
@onready var _sfx_slider: HSlider = $CenterSettings/SettingsPanel/VBox/SfxRow/SfxSlider
@onready var _key_button: Button = $CenterSettings/SettingsPanel/VBox/KeyRow/ChangeKeyButton
@onready var _key_label: Label = $CenterSettings/SettingsPanel/VBox/KeyRow/JumpKeyValue
@onready var _close_button: Button = $CenterSettings/SettingsPanel/VBox/CloseButton

var _waiting_for_key: bool = false

func _ready() -> void:
	Audio.play_music(Audio.MENU_MUSIC)

	_play_button.pressed.connect(_start_game)
	_settings_button.pressed.connect(_open_settings)
	_quit_button.pressed.connect(_quit_game)
	_close_button.pressed.connect(_close_settings)
	_key_button.pressed.connect(_begin_rebind)

	_music_slider.value_changed.connect(func(v: float) -> void: Settings.set_music_volume(v / 100.0))
	_sfx_slider.value_changed.connect(func(v: float) -> void: Settings.set_sfx_volume(v / 100.0))

	for button in [_play_button, _settings_button, _quit_button, _close_button, _key_button]:
		button.mouse_entered.connect(func() -> void: Audio.play_sfx("ui_hover"))

	_music_slider.value = Settings.music_volume * 100.0
	_sfx_slider.value = Settings.sfx_volume * 100.0
	_settings_center.visible = false
	_refresh_key_label()
	_play_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not _waiting_for_key:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_waiting_for_key = false
		if event.keycode != KEY_ESCAPE:
			Settings.set_jump_key(event.physical_keycode)
		_refresh_key_label()
		get_viewport().set_input_as_handled()

func _start_game() -> void:
	Audio.play_sfx("ui_select")
	get_tree().change_scene_to_file(GAME_SCENE)

func _quit_game() -> void:
	Audio.play_sfx("ui_select")
	get_tree().quit()

func _open_settings() -> void:
	Audio.play_sfx("ui_select")
	_buttons.visible = false
	_settings_center.visible = true

func _close_settings() -> void:
	Audio.play_sfx("ui_select")
	_settings_center.visible = false
	_buttons.visible = true
	_settings_button.grab_focus()

func _begin_rebind() -> void:
	_waiting_for_key = true
	_key_label.text = "press any key..."
	_key_button.text = "Listening"
	_key_button.disabled = true

func _refresh_key_label() -> void:
	_key_label.text = Settings.jump_key_label()
	_key_button.text = "Change"
	_key_button.disabled = false
