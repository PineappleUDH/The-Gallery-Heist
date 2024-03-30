extends "res://Scenes/Objects/Collectables/collectable.gd"


func _ready():
	_idle_movement = IdleMovement.sin_wave

# TODO: pickup sound for this and pie. move sounds from player class
func _collected(player : Player):
	player.add_score(1)
	queue_free()
