class_name Level
extends Node2D

signal score_changed

enum SaulLetter {S, A, U, L}

# level dependencies
@onready var player : Player = $Saul
@onready var interface : CanvasLayer = $UI
@onready var pause_manager : MarginContainer = $UI/PauseManager
@onready var level_camera : LevelCamera = $LevelCamera
@onready var tilemap : TileMap = $TileMap
@onready var music_player : Node = $Audio/MusicPlayer
@onready var dialogue_player : MarginContainer = $UI/DialoguePlayer
const tile_size : int = 16

@onready var _screen_transition : TextureRect = $UI/ScreenTransition

var _score : int = 0
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

func _input(event : InputEvent):
	if event.is_action_pressed("pause"):
		pause_manager.pause(true)

func add_score(amount : int = 1):
	_score += amount
	interface.set_score(_score)
	score_changed.emit()

func get_score() -> int:
	return _score

func set_checkpoint(checkpoint : Checkpoint):
	if _checkpoint:
		_checkpoint.uncheck()
	
	_checkpoint = checkpoint

func found_letter(letter : SaulLetter):
	assert(_found_letters[letter] == false, "Letter already found, make sure the level only has 1 of each letter")
	_found_letters[letter] = true
	interface.show_letters_found(_found_letters)

func _on_player_died():
	_screen_transition.transition()
	await _screen_transition.screen_hidden
	
	if _checkpoint:
		player.reset_from_checkpoint(_checkpoint.get_spawn_position())
	else:
		player.reset_from_checkpoint(_player_starting_position)
