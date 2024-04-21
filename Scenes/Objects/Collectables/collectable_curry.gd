extends "res://Scenes/Objects/Collectables/collectable.gd"

const _amount_healed : int = 1

#TODO: SoundFX

func _ready():
	_bob_height = 3
	_bob_speed = 2
	_idle_movement = IdleMovement.sin_wave

func _collected(player : Player):
	player.heal(_amount_healed)
	queue_free()
