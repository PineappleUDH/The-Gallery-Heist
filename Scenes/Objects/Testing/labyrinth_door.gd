extends Node2D

signal level_entered(scene : String)

@export var _labyrinth_scene_name : String

@onready var _sprite : AnimatedSprite2D = $Sprite2D

const _labyrinth_levels_path : String = "res://Scenes/Game/Levels/Labyrinth/"
var _finished : bool

func set_finished(finished : bool):
	_finished = finished
	if finished:
		_sprite.play("finished")
	else:
		_sprite.play("closed")

func _on_interactable_player_interacted():
	level_entered.emit(_labyrinth_levels_path + _labyrinth_scene_name + ".tscn")

func _on_interactable_body_entered(body : Node2D):
	if body is Player:
		_sprite.play("opened")

func _on_interactable_body_exited(body : Node2D):
	if body is Player:
		_sprite.play("finished" if _finished else "closed")
