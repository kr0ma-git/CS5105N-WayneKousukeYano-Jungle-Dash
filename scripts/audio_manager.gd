extends Node

## Central audio player, registered as the "Audio" autoload.
##
## SFX play on the "SFX" bus and music on the "Music" bus, so the two can be
## balanced separately (the Settings menu drives those bus volumes). A small
## pool of players is reused so overlapping sounds (jump + land) don't cut each
## other off.

const MENU_MUSIC := "res://assets/ch_03_game_systems/music/title_01.ogg"
const GAME_MUSIC := "res://assets/ch_03_game_systems/music/forest_01.ogg"

const SFX := {
	"jump": preload("res://assets/ch_04_player_abilities/audio/jump.wav"),
	"land": preload("res://assets/ch_04_player_abilities/audio/land.wav"),
	"hurt": preload("res://assets/ch_04_player_abilities/audio/hit.wav"),
	"death": preload("res://assets/ch_04_player_abilities/audio/death.wav"),
	"boom": preload("res://assets/ch_04_player_abilities/audio/boom.wav"),
	"ui_select": preload("res://assets/ch_03_game_systems/audio/ui_select_audio.wav"),
	"ui_hover": preload("res://assets/ch_03_game_systems/audio/ui_bloop_audio.wav"),
}

const SFX_POOL_SIZE := 8

var _music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _current_music: String = ""

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)

## Plays a looping music track, doing nothing if it is already playing.
func play_music(path: String) -> void:
	if _current_music == path and _music.playing:
		return
	_current_music = path
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music.stream = stream
	_music.play()

func stop_music() -> void:
	_music.stop()
	_current_music = ""

## Plays a one-shot effect by its key in SFX (see the dictionary above).
func play_sfx(key: String) -> void:
	if not SFX.has(key):
		return
	var stream: AudioStream = SFX[key]
	for player in _sfx_pool:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	# Every voice is busy: steal the first one.
	_sfx_pool[0].stream = stream
	_sfx_pool[0].play()
