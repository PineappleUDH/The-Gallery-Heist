@tool
extends Area2D

signal applied_damage

## if true only deals damage to player
@export var _target_player_only : bool = false
## the damage value to apply
@export var damage : int = 1
## kills in one hit
@export var is_deadly : bool = false :
	set(value):
		is_deadly = value
		notify_property_list_changed()
## for damaging objects that knocks-back in a specific direction like spikes
@export var custom_knockback_direction : Vector2 = Vector2.ZERO

var _collision_center : Vector2 = Vector2.ZERO

func _ready():
	if Engine.is_editor_hint(): return
	
	set_physics_process(false)
	
	# calculate collision center to use for knockback direction. without this we can only apply the knockback
	# from the direction of our position which isn't ideal because the position isn't guarenteed to be
	# at the center of the collision shape(s). this ensures that the knockback is applied from the direction of the collision center
	var shapes_count : int = 0
	for child in get_children():
		if child is CollisionShape2D:
			_collision_center += child.position
			shapes_count += 1
			
		elif child is CollisionPolygon2D:
			assert(false, "CollisionPolygon2D not supported. no clean way to get collider center")
	
	_collision_center /= shapes_count

func _physics_process(delta : float):
	if Engine.is_editor_hint(): return
	
	if monitoring:
		for body : Node2D in get_overlapping_bodies():
			if _is_valid_damage_receiver(body):
				var knockback : Vector2 =\
					custom_knockback_direction if custom_knockback_direction != Vector2.ZERO\
					else (body.global_position - (global_position + _collision_center)).normalized()
				
				var damage_taken : bool = body.take_damage(
					damage,
					knockback,
					is_deadly
				)
				
				if damage_taken:
					applied_damage.emit()

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
	
	set_physics_process(damagable_character_in_area)

func _is_valid_damage_receiver(body : Node2D) -> bool:
	return (body != get_parent() && body is Character &&
		(_target_player_only == false || (_target_player_only && body is Player)))

func _validate_property(property : Dictionary):
	if property["name"] == "damage":
		if is_deadly:
			property["usage"] = PROPERTY_USAGE_NO_EDITOR
