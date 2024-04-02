extends "res://Scenes/Objects/Collectables/collectable.gd"

@onready var _collider : CollisionShape2D = $CollisionShape2D
@onready var _reset_timer = $ResetTimer
@onready var _sprite = $Sprite2D


func _ready():
	_idle_movement = IdleMovement.sin_wave

func _collected(player : Player):
	if player.can_dash() == false:
		player.refill_dash()
		_collider.set_deferred("disabled", true)
		modulate.a = 0.2
		_sprite.frame = 1
		_reset_timer.start()

func _on_reset_timer_timeout():
	_collider.disabled = false
	_sprite.frame = 0
	modulate.a = 1.0
