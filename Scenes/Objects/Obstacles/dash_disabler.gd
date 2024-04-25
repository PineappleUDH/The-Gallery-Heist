@tool
extends Node2D

@export var _radius : float :
	set(value):
		_radius = max(value, 0.0)
		if is_inside_tree() == false:
			await ready
		
		_area_collider.shape.radius = _radius

@onready var _sprite : Sprite2D = $Sprite2D
@onready var _area : Area2D = $Area2D
@onready var _particles : GPUParticles2D = $GPUParticles2D
@onready var _area_collider : CollisionShape2D = $Area2D/CollisionShape2D

const _sprite_on_x : float = 0.0
const _sprite_off_x : float = 16.0
const _area_circle_color : Color = Color("ac323222")
var _player_inside : bool = false


func _ready():
	set_process(false)

func _draw():
	if Engine.is_editor_hint(): return
	
	if _player_inside:
		draw_circle(_area.position, _area_collider.shape.radius, _area_circle_color)

func _process(delta : float):
	var direction : Vector2 = World.level.player.global_position - global_position
	var distance : float = global_position.distance_to(World.level.player.global_position)
	
	_particles.process_material.emission_box_extents.y = distance
	_particles.position = direction.normalized() * distance / 2.0
	_particles.rotation = direction.angle() + PI/2.0

func _on_body_entered(body : Node2D):
	if body is Player:
		_sprite.texture.region.position.x = _sprite_on_x
		_player_inside = true
		_particles.emitting = true
		body.set_dash_lock(true)
		queue_redraw()
		set_process(true)

func _on_body_exited(body : Node2D):
	if body is Player:
		_sprite.texture.region.position.x = _sprite_off_x
		_player_inside = false
		_particles.emitting = false
		body.set_dash_lock(false)
		queue_redraw()
		set_process(false)
