extends "res://Scenes/Objects/Collectables/collectable.gd"

signal key_collected

func _ready():
	_idle_movement = IdleMovement.sin_wave

func _collected(player : Player):
	key_collected.emit()
	queue_free()
