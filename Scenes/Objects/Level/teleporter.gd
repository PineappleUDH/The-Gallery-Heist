extends Area2D
class_name Teleporter

@export var _target_teleporter : Teleporter
@onready var output_location = $OutputLocation
var _player_in_range : bool = false
var _subject

func _player_interacting():
	_teleport_subject()

func _teleport_subject():
	_subject.global_position = _target_teleporter._output_location.global_position

func _on_body_entered(body):
	if body.is_in_group("Player"):
		_subject = body
		_player_in_range = true
		print(_subject)

func _on_body_exited(body):
	if body.is_in_group("Player"):
		_subject = null
		_player_in_range = false
