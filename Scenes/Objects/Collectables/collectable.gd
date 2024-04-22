class_name Collectable
extends Area2D

enum IdleMovement {none, sin_wave, shake}

@onready var _start_y : float = global_position.y

var _idle_movement : IdleMovement = IdleMovement.none

var _sin_height : float = 5.0
var _sin_speed : float = 4.0
var _sin_delta : float = 0.0

func _process(delta : float):
	match _idle_movement:
		IdleMovement.sin_wave:
			_sin_delta += delta
			global_position.y =\
				_start_y + (sin(_sin_delta * _sin_speed) * _sin_height)

# override
func _collected(player : Player):
	queue_free()

func _on_body_entered(body : Node2D):
	if body is Player:
		_collected(body)
