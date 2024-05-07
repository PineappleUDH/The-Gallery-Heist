extends "res://Scenes/Objects/Collectables/collectable.gd"

func _ready():
	_idle_movement = IdleMovement.sin_wave

func _collected(player : Player):
	super._collected(player)
