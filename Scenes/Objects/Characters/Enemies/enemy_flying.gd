@tool
extends "res://Scenes/Objects/Characters/Enemies/enemy.gd"

@export var _max_speed : float = 180.0

@onready var _sprite : AnimatedSprite2D = $AnimatedSprite2D

const _acceleration : float = 350.0
const _deceleration : float = 160.0
var _path : Path2D
var _path_points : PackedVector2Array
var _path_target_point : int = 0
const _point_reached_min_distance : float = 32.0

func _ready():
	if Engine.is_editor_hint(): return
	
	_max_health = 2
	_damage_cooldown_time = 2.0
	_health = _max_health
	_knockback = 20.0
	
	for child in get_children():
		if child is Path2D:
			_path = child
	assert(_path != null, "Add a Path2d child representing the flying path")
	
	_path.position = _path.global_position
	_path.top_level = true # make the path top_level so it has its own transform
	_path_points = _path.curve.tessellate()
	assert(_path_points.size() >= 2, "Path needs at least 2 points to work")
	
	for i in _path_points.size(): _path_points[i] += _path.global_position
	global_position = _path_points[_path_target_point]
	_path_target_point += 1

func _physics_process(delta : float):
	if Engine.is_editor_hint(): return
	
	var dir : Vector2 =\
		(_path_points[_path_target_point] - global_position).normalized()
	# accelerate
	velocity.x = Utilities.soft_clamp(velocity.x, dir.x * _acceleration * delta, _max_speed)
	velocity.y = Utilities.soft_clamp(velocity.y, dir.y * _acceleration * delta, _max_speed)
	
	# decelerate
	velocity.x = Utilities.soft_clamp(velocity.x, -sign(velocity.x) * _deceleration * delta, 0.0)
	velocity.y = Utilities.soft_clamp(velocity.y, -sign(velocity.y) * _deceleration * delta, 0.0)
	
	if velocity.x > 0.0:
		_sprite.flip_h = false
	elif velocity.x < 0.0:
		_sprite.flip_h = true
	
	move_and_slide()
	
	if global_position.distance_to(_path_points[_path_target_point]) <= _point_reached_min_distance:
		_path_target_point = (_path_target_point + 1) % _path_points.size()

func _get_configuration_warnings() -> PackedStringArray:
	for child in get_children():
		if child is Path2D:
			return []
	
	return ["Flying enemy requires a Path2D node as a child used to represent its flying path"]
