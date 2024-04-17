class_name Checkpoint
extends Area2D

@onready var _sprite : AnimatedSprite2D = $Sprite2D
@onready var _hologram : Sprite2D = $Hologram
@onready var _spawn_marker : Marker2D = $SpawnMarker
@onready var _particles : GPUParticles2D = $GPUParticles2D

# TODO: default camera trigger that gets applied on respawn so we don't
#       need to place additional trigger colliders on every checkpoint
#       same for other triggers I guess like the music trigger

var _is_checked : bool


func uncheck():
	_is_checked = false
	_hologram.hide()
	_sprite.play("inactive")

func get_spawn_position() -> Vector2:
	return _spawn_marker.global_position

func _on_body_entered(body : Node2D):
	if body is Player:
		if _is_checked == false:
			_is_checked = true
			_hologram.show()
			_particles.restart()
			World.level.set_checkpoint(self)
			_sprite.play("activating")
			_sprite.play("active")
		
		# heal player to full health, players might kill themselves near a checkpoint to heal
		# might as well make the process less annoying
		World.level.player.heal(999)
