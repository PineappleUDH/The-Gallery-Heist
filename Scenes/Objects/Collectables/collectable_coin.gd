extends "res://Scenes/Objects/Collectables/collectable.gd"


func _ready():
	_idle_movement = IdleMovement.sin_wave

func _collected(player : Player):
	player.add_score(1)
	queue_free()
