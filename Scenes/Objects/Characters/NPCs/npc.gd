extends "res://Scenes/Objects/Characters/character.gd"


func _ready():
	_max_health = 1
	_health = _max_health
	_damage_cooldown_time = 0.0
	_is_invincible = true # NPCs don't die

# TODO: dialogue related functions, maybe some basic movement and animations control
