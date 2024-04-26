class_name Collectable
extends Area2D

enum IdleMovement {none, sin_wave, shake}

@onready var _start_pos : Vector2 = global_position

var _idle_movement : IdleMovement = IdleMovement.none

var _sin_height : float = 5.0
var _sin_speed : float = 4.0
var _sin_delta : float = 0.0

var _shake_strength : float = 35.0

func _process(delta : float):
	match _idle_movement:
		IdleMovement.sin_wave:
			_sin_delta += delta
			global_position.y =\
				_start_pos.y + (sin(_sin_delta * _sin_speed) * _sin_height)
		IdleMovement.shake:
			global_position = _start_pos + Vector2(
				randf_range(-_shake_strength, _shake_strength), randf_range(-_shake_strength, _shake_strength)
			) * delta

# override
func _collected(player : Player):
	queue_free()

func _on_body_entered(body : Node2D):
	if body is Player:
		_collected(body)
