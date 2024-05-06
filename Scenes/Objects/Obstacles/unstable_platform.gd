@tool
extends StaticBody2D

enum _State {restore, solid, destoy, empty}

@export var _count : int :
	set(value):
		_count = max(value, 1)
		
		if is_node_ready() == false:
			await ready
		
		for sprite in _sprites_container.get_children():
			sprite.queue_free()
		
		for i in _count:
			var sprite : Sprite2D = Sprite2D.new()
			sprite.texture = AtlasTexture.new()
			sprite.texture.atlas = preload("res://Resources/Textures/unstable_platform.png")
			var region_x : int
			if _count == 1:
				region_x = 16 # lone piece
			elif i == 0:
				region_x = 0 # left edge
			elif i == _count-1:
				region_x = 32 # right edge
			else:
				region_x = 16 # center
			
			sprite.texture.region = Rect2i(
				region_x, 0, 16, 16
			)
			sprite.position = Vector2(8.0 + i * 16.0, 8.0)
			_sprites_container.add_child(sprite)
		
		_collider.shape.size = Vector2(
			16 * _count,
			16
		)
		_collider.position = _collider.shape.size / 2.0
		
		_detection_collider.shape.size = Vector2(_collider.shape.size.x, 1.0)
		_detection_collider.position = Vector2(
			_detection_collider.shape.size.x / 2.0,
			0.0
		)
		
		_particles.amount = min(_count * _particles_per_sprite, _max_particles)
		_particles.position = Vector2(8.0 * _count, 8.0)
		_particles.process_material.emission_box_extents.x = _particles.position.x

@onready var _sprites_container : Node2D = $Sprites
@onready var _collider : CollisionShape2D = $CollisionShape2D
@onready var _detection_collider : CollisionShape2D = $PlayerDetection/CollisionShape2D
@onready var _particles : GPUParticles2D = $GPUParticles2D
@onready var _timer : Timer = $Timer

var _current_state = _State.solid
const _destroyed_transparency : float = 0.4
const _destruction_time : float = 0.8
const _empty_time : float = 1.4
const _restoration_time : float = 0.4
const _particles_per_sprite : int = 10
const _max_particles : int = 100


func _on_detection_body_entered(body : Node2D):
	if body is Player && _current_state == _State.solid:
		_current_state = _State.destoy
		_timer.wait_time = _destruction_time
		_on_timer_timeout()

func _on_timer_timeout():
	match _current_state:
		_State.destoy:
			_particles.restart()
			for sprite in _sprites_container.get_children():
				sprite.texture.region.position.y += 16
			
			var region_x : float = _sprites_container.get_child(0).texture.region.position.y
			if region_x == 48:
				# fully destroyed
				_current_state = _State.empty
				_collider.disabled = true
				_detection_collider.disabled = true
				_timer.wait_time = _empty_time
			
			_timer.start()
		
		_State.empty:
			# wait a little before rebuilding
			_current_state = _State.restore
			_timer.wait_time = _restoration_time
			_timer.start()
		
		_State.restore:
			modulate.a = _destroyed_transparency
			for sprite in _sprites_container.get_children():
				sprite.texture.region.position.y -= 16
			
			var region_x : float = _sprites_container.get_child(0).texture.region.position.y
			if region_x == 0:
				# fully restored
				_current_state = _State.solid
				_collider.disabled = false
				_detection_collider.disabled = false
				modulate.a = 1.0
			
			else:
				_timer.start()
