@tool
extends StaticBody2D

## the number of spikes
@export var _count : int :
	set(value):
		_count = max(value, 1)
		
		if is_node_ready() == false:
			await ready
		
		# sprites
		for child : Sprite2D in _sprites_container.get_children():
			child.queue_free()
		var spike_texture : Texture2D = preload("res://Resources/Textures/Spike.png")
		for i in _count:
			var sprite : Sprite2D = Sprite2D.new()
			sprite.texture = spike_texture
			sprite.position = Vector2(
				spike_texture.get_size().x * i + spike_texture.get_size().x / 2.0, 0.0
			)
			_sprites_container.add_child(sprite)
		
		# hurtbox
		_hurtbox_collider.shape.size = Vector2(
			spike_texture.get_size().x * _count,
			spike_texture.get_size().y / 2.0
		)
		_hurtbox_collider.position = _hurtbox_collider.shape.size / 2.0
		
		# collider
		_collider.shape.size = Vector2(
			spike_texture.get_size().x * _count, 1.0 # 1 pixel high just enough to stand on it
		)
		_collider.position = Vector2(
			_collider.shape.size.x / 2.0,
			spike_texture.get_size().y / 2.0 + 0.5
		)

@onready var _collider : CollisionShape2D = $CollisionShape2D
@onready var _hurtbox_collider : CollisionShape2D = $HurtBox/CollisionShape2D
@onready var _sprites_container : Node2D = $Sprites
