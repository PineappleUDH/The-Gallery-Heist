extends Area2D
class_name Teleporter

@export var _target_teleporter : Teleporter

@onready var output_location : Node2D = $OutputLocation

func _on_interactable_player_interacted():
	World.level.player.global_position = _target_teleporter.output_location.global_position
