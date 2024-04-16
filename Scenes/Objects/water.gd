@tool
extends Area2D

@export var _width_tiles : int :
	set(value):
		_width_tiles = max(1, value)
		_update_area()
@export var _height_tiles : int :
	set(value):
		_height_tiles = max(1, value)
		_update_area()

@onready var _collider : CollisionShape2D = $CollisionShape2D

# TODO: visuals

func _update_area():
	if is_inside_tree() == false:
		await ready
	
	_collider.shape.size = Vector2(
		_width_tiles * Level.tile_size,
		_height_tiles * Level.tile_size
	)
	_collider.position = _collider.shape.size / 2.0

func _on_body_entered(body : Node2D):
	if body is Player:
		# TODO: muffle some sounds, would need to separate buses
		body.water_area(true)

func _on_body_exited(body : Node2D):
	if body is Player:
		body.water_area(false)
