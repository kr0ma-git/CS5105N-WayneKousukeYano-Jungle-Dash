extends Node

## Global player settings, saved to disk so they stick between runs.
##
## Registered as the "Settings" autoload. It owns three things:
##   * the Music and SFX bus volumes (0..1)
##   * the key bound to the "jump" action  <- the accessibility feature
## Anything the player changes in the Settings menu lands here and is written to
## user://settings.cfg, then re-applied on the next launch.

signal changed

const CONFIG_PATH := "user://settings.cfg"
const JUMP_ACTION := "jump"
## W always stays a jump key alongside the chosen one, so the classic binding
## never breaks.
const ALT_JUMP_KEY := KEY_W

var music_volume: float = 0.7
var sfx_volume: float = 0.8
var jump_keycode: int = KEY_SPACE
## Longest run so far, in metres. Shown on the HUD and the game-over screen.
var best_distance: float = 0.0

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		music_volume = float(cfg.get_value("audio", "music", music_volume))
		sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))
		jump_keycode = int(cfg.get_value("input", "jump", jump_keycode))
		best_distance = float(cfg.get_value("progress", "best", best_distance))
	apply_all()

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("input", "jump", jump_keycode)
	cfg.set_value("progress", "best", best_distance)
	cfg.save(CONFIG_PATH)

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	save_settings()
	changed.emit()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	save_settings()
	changed.emit()

func set_jump_key(keycode: int) -> void:
	jump_keycode = keycode
	_apply_jump_key()
	save_settings()
	changed.emit()

## Records a new personal best, but only if it really is one.
func set_best_distance(metres: float) -> void:
	if metres <= best_distance:
		return
	best_distance = metres
	save_settings()
	changed.emit()

func apply_all() -> void:
	_apply_volumes()
	_apply_jump_key()

func jump_key_label() -> String:
	return OS.get_keycode_string(jump_keycode)

func _apply_volumes() -> void:
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)

func _set_bus_volume(bus_name: String, value: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	if value <= 0.001:
		AudioServer.set_bus_mute(index, true)
	else:
		AudioServer.set_bus_mute(index, false)
		AudioServer.set_bus_volume_db(index, linear_to_db(value))

func _apply_jump_key() -> void:
	if not InputMap.has_action(JUMP_ACTION):
		InputMap.add_action(JUMP_ACTION)
	InputMap.action_erase_events(JUMP_ACTION)
	_add_key(JUMP_ACTION, jump_keycode)
	if jump_keycode != ALT_JUMP_KEY:
		_add_key(JUMP_ACTION, ALT_JUMP_KEY)

func _add_key(action: String, keycode: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode as Key
	InputMap.action_add_event(action, event)