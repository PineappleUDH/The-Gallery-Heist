@tool
extends Node2D

@export var _radius : float :
	set(value):
		_radius = max(value, 0.0)
		if is_inside_tree() == false:
			await ready
		
		_area_collider.shape.radius = _radius

@onready var _eye_animator : AnimationPlayer = $Eye/AnimationPlayer
@onready var _eye_sprite : Sprite2D = $Eye
@onready var _pupil_sprite : Sprite2D = $Eye/Pupil
@onready var _particles : GPUParticles2D = $GPUParticles2D
@onready var _area_collider : CollisionShape2D = $Area2D/CollisionShape2D
@onready var _dodge_area_collider : CollisionShape2D = $DodgeArea/CollisionShape2D

const _pupil_max_offset : float = 8.0
const _big_pupil_tex_pos : float = 0.0
const _small_pupil_tex_pos : float = 32.0
const _eye_dodge_lerp_speed : float = 20.0
const _particles_amount_max_distance : float = 600.0 # particles amount won't increase after this distance from player
var _player_inside : bool = false
var _player_inside_dodge : bool = false

func _process(delta : float):
	if _player_inside:
		var direction : Vector2 = (World.level.player.global_position - _eye_sprite.global_position).normalized()
		var distance : float = _eye_sprite.global_position.distance_to(World.level.player.global_position)
		
		_particles.process_material.emission_box_extents.y = distance / 2.0
		# Note: godot doesn't allow changing particles amount without reseting github.com/godotengine/godot-proposals/issues/5939
		#       a workaround is to set amount to max possible amount and use amount_ratio to show part of it
		_particles.amount_ratio = remap(distance, 0.0, _particles_amount_max_distance, 0.0, 1.0)
		_particles.position = direction * distance / 2.0
		_particles.rotation = direction.angle() + PI/2.0
		
		_pupil_sprite.position = direction * _pupil_max_offset
	
	if _player_inside_dodge:
		# dodge player
		var direction : Vector2 = (World.level.player.global_position - _eye_sprite.global_position).normalized()
		_eye_sprite.position = lerp(
			_eye_sprite.position, -direction * _dodge_area_collider.shape.radius / 2.0, _eye_dodge_lerp_speed * delta
		)
	elif _player_inside_dodge == false && _eye_sprite.position != Vector2.ZERO:
		# go back to original pos
		_eye_sprite.position = lerp(
			_eye_sprite.position, Vector2.ZERO, _eye_dodge_lerp_speed * delta
		)

func _on_animation_started(anim_name : StringName):
	if is_node_ready() == false: return # this gets called with the starting animation before node is ready
	
	if anim_name == "open":
		_pupil_sprite.show()
	else:
		_pupil_sprite.hide()

func _on_body_entered(body : Node2D):
	if body is Player:
		_eye_animator.clear_queue()
		_eye_animator.play("opening")
		_eye_animator.queue("open")
		_player_inside = true
		_particles.emitting = true
		body.set_dash_lock(true)
		queue_redraw()

func _on_body_exited(body : Node2D):
	if body is Player:
		_eye_animator.clear_queue()
		_eye_animator.play("closing")
		_eye_animator.queue("closed")
		_player_inside = false
		_particles.emitting = false
		body.set_dash_lock(false)
		queue_redraw()

func _on_dodge_area_body_entered(body : Node2D):
	if body is Player:
		_player_inside_dodge = true
		_pupil_sprite.texture.region.position.x = _big_pupil_tex_pos

func _on_dodge_area_body_exited(body : Node2D):
	if body is Player:
		_player_inside_dodge = false
		_pupil_sprite.texture.region.position.x = _small_pupil_tex_pos
