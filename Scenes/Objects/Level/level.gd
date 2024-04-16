class_name Level
extends Node2D

# TODO: level should handles:
#       UI and score
#       dialogue player object

enum SaulLetter {S, A, U, L}

# level dependencies
@onready var player : Player = $Characters/Saul
@onready var level_camera : LevelCamera = $LevelCamera
@onready var music_player : Node = $Audio/MusicPlayer
const tile_size : int = 16

@onready var _screen_transition : TextureRect = $Transition/ScreenTransition

var _found_letters : Dictionary = {
	SaulLetter.S:false,
	SaulLetter.A:false,
	SaulLetter.U:false,
	SaulLetter.L:false,
}

var _player_starting_position : Vector2
var _checkpoint : Checkpoint = null


func _ready():
	player.died.connect(_on_player_died)
	
	# initial checkpoint is spawn point
	_player_starting_position = player.global_position

func set_checkpoint(checkpoint : Checkpoint):
	if _checkpoint:
		_checkpoint.uncheck()
	
	_checkpoint = checkpoint

func found_letter(letter : SaulLetter):
	assert(_found_letters[letter] == false, "Letter already found, make sure the level only has 1 of each letter")
	_found_letters[letter] = true

func _on_player_died():
	_screen_transition.transition()
	await _screen_transition.screen_hidden
	
	if _checkpoint:
		player.reset_from_checkpoint(_checkpoint.get_spawn_position())
	else:
		player.reset_from_checkpoint(_player_starting_position)
