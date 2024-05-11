@tool
class_name Interactable
extends Area2D

signal player_interacted

@onready var _prompt : AnimatedSprite2D = $Prompt
var _prompt_marker : Marker2D

func _ready():
	if Engine.is_editor_hint(): return
	
	_prompt.hide()
	for child in get_children():
		if child is Marker2D:
			_prompt_marker = child
			break

func _get_configuration_warnings() -> PackedStringArray:
	for child in get_children():
		if child is Marker2D:
			return []
	
	return ["Interactable needs a marker representing where the interact prompt will be shown"]

func _on_body_entered(body : Node2D):
	if body is Player:
		if _prompt_marker:
			_prompt.global_position = _prompt_marker.global_position
		_prompt.show()
		body.interacted.connect(_player_interacted)

func _on_body_exited(body : Node2D):
	if body is Player:
		_prompt.hide()
		body.interacted.disconnect(_player_interacted)

func _player_interacted():
	player_interacted.emit()
