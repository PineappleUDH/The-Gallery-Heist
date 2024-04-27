@tool
extends Node2D

@export var _radius : float :
	set(value):
		_radius = max(value, 0.0)
		if is_inside_tree() == false:
			await ready
		
		_area_collider.shape.radius = _radius

@onready var _eye_sprite : Sprite2D = $Eye
@onready var _eye_animator : AnimationPlayer = $Eye/AnimationPlayer
@onready var _pupil_sprite : Sprite2D = $Eye/Pupil
@onready var _area : Area2D = $Area2D
@onready var _particles : GPUParticles2D = $GPUParticles2D
@onready var _area_collider : CollisionShape2D = $Area2D/CollisionShape2D

const _pupil_max_offset : float = 8.0
const _particles_amount_max_distance : float = 600.0 # particles amount won't increase after this distance from player
const _area_circle_color : Color = Color("ac323222")
var _player_inside : bool = false

# TODO: make eye dodge player when they try to reach it, the dodgine
#       should occur around a small radius and not affect disabler radius
#       use the other pupil sprite while dodging. also the eye should shake or something

func _ready():
	set_process(false)

func _draw():
	if Engine.is_editor_hint(): return
	
	if _player_inside:
		draw_circle(_area.position, _area_collider.shape.radius, _area_circle_color)

func _process(delta : float):
	var direction : Vector2 = World.level.player.global_position - global_position
	var distance : float = global_position.distance_to(World.level.player.global_position)
	
	_particles.process_material.emission_box_extents.y = distance / 2.0
	# Note: godot doesn't allow changing particles amount without reseting github.com/godotengine/godot-proposals/issues/5939
	#       a workaround is to set amount to max possible amount and use amount_ratio to show part of it
	_particles.amount_ratio = remap(distance, 0.0, _particles_amount_max_distance, 0.0, 1.0)
	_particles.position = direction.normalized() * distance / 2.0
	_particles.rotation = direction.angle() + PI/2.0
	
	_pupil_sprite.position = direction.normalized() * _pupil_max_offset

func _on_body_entered(body : Node2D):
	if body is Player:
		_eye_animator.clear_queue()
		_eye_animator.play("opening")
		_eye_animator.queue("open")
		_player_inside = true
		_particles.emitting = true
		body.set_dash_lock(true)
		queue_redraw()
		set_process(true)

func _on_body_exited(body : Node2D):
	if body is Player:
		_eye_animator.clear_queue()
		_eye_animator.play("closing")
		_eye_animator.queue("closed")
		_player_inside = false
		_particles.emitting = false
		body.set_dash_lock(false)
		queue_redraw()
		set_process(false)

func _on_animation_started(anim_name : StringName):
	if is_node_ready() == false: return # this gets called with the starting animation before node is ready
	
	if anim_name == "open":
		_pupil_sprite.show()
	else:
		_pupil_sprite.hide()
