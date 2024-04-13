class_name Checkpoint
extends Area2D

@onready var _sprite : AnimatedSprite2D = $Sprite2D
@onready var _spawn_marker : Marker2D = $SpawnMarker
@onready var _particles : GPUParticles2D = $GPUParticles2D

var _is_checked : bool


func uncheck():
	_is_checked = false
	_sprite.play("inactive")

func get_spawn_position() -> Vector2:
	return _spawn_marker.global_position

func _on_body_entered(body : Node2D):
	if body is Player && _is_checked == false:
		_is_checked = true
		World.level.set_checkpoint(self)
		_particles.restart()
		_sprite.play("activating")
		_sprite.play("active")
