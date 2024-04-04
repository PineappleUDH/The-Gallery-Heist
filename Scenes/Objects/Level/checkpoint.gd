class_name Checkpoint
extends Area2D

@onready var _sprite : Sprite2D = $Sprite2D
@onready var _spawn_marker : Marker2D = $SpawnMarker

var _is_checked : bool
const _unchecked_texture_x : float = 0.0
const _checked_texture_x : float = 64.0


func uncheck():
	_is_checked = false
	_sprite.region_rect.position.x = _unchecked_texture_x

func get_spawn_position() -> Vector2:
	return _spawn_marker.global_position

func _on_body_entered(body : Node2D):
	if body is Player && _is_checked == false:
		World.level.set_checkpoint(self)
		_is_checked = true
		_sprite.region_rect.position.x = _checked_texture_x
