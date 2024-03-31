class_name Character
extends CharacterBody2D

signal died

@onready var _damaged_sfx : AudioStreamPlayer2D = $Sounds/Damaged

@warning_ignore("unused_private_class_variable")
var _gravity : int = ProjectSettings.get_setting("physics/2d/default_gravity")
@warning_ignore("unused_private_class_variable")
var _direction : Vector2 = Vector2.RIGHT
@warning_ignore("unused_private_class_variable")
var _max_health : float
var _health : float
var _is_invincible : bool
var _knockback_multiplier : float = 1.0


func _process(delta : float):
	if global_position.y > Level.death_height_y:
		take_damage(0, 0.0, Vector2.ZERO, true)

# override
func take_damage(damage : int, knockback : float, from : Vector2, is_deadly : bool = false):
	if _is_invincible: return
	
	if is_deadly:
		_health = 0
	else:
		_health -= damage
	
	if _health > 0:
		velocity -= (from - global_position).normalized() * knockback * _knockback_multiplier
		_damage_taken(damage, false)
		
	else:
		_damage_taken(damage, true)

# override
func _damage_taken(damage : int, die : bool):
	if die:
		queue_free()
		died.emit()
	else:
		_damaged_sfx.play()
