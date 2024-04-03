class_name Level
extends Node2D

# TODO: level should handles:
#       UI and score
#       dialogue player object
const death_height_y : float = 0.0

# level dependencies
@onready var player : Player = $Characters/Saul
@onready var level_camera : LevelCamera = $LevelCamera
@onready var music_player : Node = $Audio/MusicPlayer


func _ready():
	player.died.connect(_on_player_died)

func _on_player_died():
	SceneManager.restart_scene()
