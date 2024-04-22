@tool
extends "res://Scenes/Objects/Characters/Enemies/enemy.gd"

@export var _speed : float = 80.0

@onready var _path_follow : PathFollow2D = $PathFollow2D
@onready var _sprite : Sprite2D = $Sprite2D

var _path : Path2D

func _ready():
	if Engine.is_editor_hint(): return
	
	_max_health = 2
	_damage_cooldown_time = 2.0
	_health = _max_health
	_knockback = 130.0
	
	for child in get_children():
		if child is Path2D:
			_path = child
	assert(_path != null, "Add a Path2d child representing the flying path")
	
	_path.position = _path.global_position
	_path.top_level = true
	remove_child(_path_follow)
	_path.add_child(_path_follow)

func _physics_process(delta : float):
	if Engine.is_editor_hint(): return
	
	_path_follow.progress += _speed * delta
	var prev_pos : Vector2 = global_position
	global_position = _path_follow.global_position
	
	if prev_pos.x - global_position.x < 0.0:
		_sprite.flip_h = false
	elif prev_pos.x - global_position.x > 0.0:
		_sprite.flip_h = true
	
	# even though we don't use it. call move_and_slide for physics to apply
	move_and_slide()

func _get_configuration_warnings() -> PackedStringArray:
	for child in get_children():
		if child is Path2D:
			return []
	
	return ["Flying enemy requires a Path2D node as a child used to represent its flying path"]
