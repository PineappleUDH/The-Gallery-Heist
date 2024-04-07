extends Area2D

@export var _target_player_only : bool = false
@export var damage : int = 1
@export var knockback : float = 130.0 # TODO: make knockback a var of Character instead of this
@export var is_deadly : bool = false

# TODO: add 'custom_damange_direction' for nodes that don't apply damage
#       from their origin point like spikes which should always
#       have a knockback direction of up

func _ready():
	set_process(false)

func _physics_process(delta : float):
	if monitoring:
		for body : Node2D in get_overlapping_bodies():
			if _is_valid_damage_receiver(body):
				body.take_damage(damage, knockback, global_position, is_deadly)

func _on_body_entered(body : Node2D):
	_check_characters_in_area()

func _on_body_exited(body : Node2D):
	_check_characters_in_area()

func _check_characters_in_area():
	var damagable_character_in_area : bool = false
	if monitoring:
		for overlapping_body : Node2D in get_overlapping_bodies():
			if _is_valid_damage_receiver(overlapping_body):
				damagable_character_in_area = true
				break
	
	set_process(damagable_character_in_area)

func _is_valid_damage_receiver(body : Node2D) -> bool:
	return (body != get_parent() && body is Character &&
		(_target_player_only == false || (_target_player_only && body is Player)))
