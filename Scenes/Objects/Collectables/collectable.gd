class_name Collectable
extends Area2D

# TODO: delete Sprite2D, some collectables use an animation sprite or labels etc..

enum IdleMovement {none, sin_wave} # TODO: shake, etc..

@onready var _start_y : float = global_position.y

const _bob_height : float = 5.0
const _bob_speed : float = 4.0
var _bob_delta : float = 0.0
var _idle_movement : IdleMovement = IdleMovement.none

func _process(delta : float):
	match _idle_movement:
		IdleMovement.sin_wave:
			_bob_delta += delta
			global_position.y =\
				_start_y + (sin(_bob_delta * _bob_speed) * _bob_height)

# override
func _collected(player : Player):
	queue_free()

func _on_body_entered(body : Node2D):
	if body is Player:
		_collected(body)
