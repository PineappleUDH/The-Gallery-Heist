@tool
extends AnimatableBody2D

## how many tiles wide the crusher should be
@export var _width : int :
	set(value):
		_width = max(value, 2)
		_build_crusher()
## how many tiles high the crusher should be
@export var _height : int :
	set(value):
		_height = max(value, 2)
		_build_crusher()
## the max point that the crusher will reach before retracting back
@export var _max_extent : float :
	set(value):
		_max_extent = max(value, 0.0)
		_build_crusher()
## speed of the crush
@export var _crush_speed : float = 50.0
## speed of the retraction after cushing
@export var _retract_speed : float = 30.0
## cooldown time after a crush or retraction where the crusher will not move
@export var _cooldown_time : float = 1.0 :
	set(value):
		_cooldown_time = max(value, 0.0)
## the start factor between the crushers position and max extent, setting this to 1 will start the crusher at the max extent
@export_range(0, 1) var _starting_offset_factor : float :
	set(value):
		_starting_offset_factor = value
		_build_crusher()

enum _State {crushing, cooldown, retracting}

@onready var _sprites_container : Node2D = $Sprites
@onready var _collider : CollisionShape2D = $CollisionShape2D
@onready var _hurtbox : Area2D = $HurtBox
@onready var _hurtbox_collider : CollisionShape2D = $HurtBox/CollisionShape2D
@onready var _cooldown_timer : Timer = $CooldownTimer

const _crusher_texture : Texture2D = preload("res://Resources/Textures/crusher.png")
const _crush_height_color : Color = Color("ffffff64")
const _offset_color : Color = Color.WHITE

@onready var _starting_pos : Vector2 = global_position
var _end_pos : Vector2
var _state : _State = _State.crushing

func _ready():
	if Engine.is_editor_hint(): return
	
	_hurtbox.custom_knockback_direction = Vector2.DOWN.rotated(rotation)
	
	# starting offset
	_end_pos = _starting_pos + Vector2.DOWN.rotated(rotation) * _max_extent
	global_position = lerp(_starting_pos, _end_pos, _starting_offset_factor)
	
	if _cooldown_time:
		_cooldown_timer.wait_time = _cooldown_time
	
	# TODO: crusher goes out of sync at the very start. putting 2 crushers next
	#       to each other with the same variables and with one having a starting offset or 0 and the other 1
	#       shows the out of sync, it only happens at the very start for some reason and only
	#       when a scene containing the crusher is the starting scene. waiting for a bit
	#       before starting the crusher seems to fix it but it's hacky and stupid
	set_process(false)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	set_process(true)

func _process(delta : float):
	if Engine.is_editor_hint(): return
	
	if _state == _State.crushing || _state == _State.retracting:
		var speed : float =\
			(_crush_speed if _state == _State.crushing else _retract_speed) * delta
		var target_pos : Vector2 = _end_pos if _state == _State.crushing else _starting_pos
		global_position = global_position.move_toward(target_pos, speed)
		
		if global_position == target_pos:
			_state = _State.cooldown
			
			if _cooldown_time:
				_cooldown_timer.start()
		
	elif _state ==_State.cooldown:
		if _cooldown_timer.is_stopped():
			if global_position == _starting_pos:
				# crush
				_state = _State.crushing
			else:
				# retract
				_state = _State.retracting

func _draw():
	if Engine.is_editor_hint() == false: return
	
	var half_tile : Vector2 = Vector2.ONE * World.level.tile_size / 2.0
	var starting_pos : Vector2 = Vector2(
		_width * World.level.tile_size / 2.0 - half_tile.x, _height * World.level.tile_size + World.level.tile_size - half_tile.y
	)
	var end_pos : Vector2 = starting_pos + Vector2(0.0, _max_extent)
	
	# crush height
	draw_line(
		starting_pos,
		end_pos, _crush_height_color, World.level.tile_size
	)
	
	# starting offset
	draw_line(
		starting_pos,
		lerp(starting_pos, end_pos, _starting_offset_factor), _offset_color, World.level.tile_size
	)

func _build_crusher():
	if is_node_ready() == false:
		await ready
	
	for sprite : Sprite2D in _sprites_container.get_children():
		sprite.queue_free()
	
	# sprites
	for w in _width:
		for h in _height:
			var sprite : Sprite2D = Sprite2D.new()
			sprite.position = Vector2(w * World.level.tile_size, h * World.level.tile_size)
			sprite.texture = AtlasTexture.new()
			sprite.texture.atlas = _crusher_texture
			sprite.texture.region.size = Vector2.ONE * World.level.tile_size
			_sprites_container.add_child(sprite)
			
			if w > 0 && w < _width-1 && h > 0 && h < _height-1: # center
				sprite.texture.region.position = Vector2(World.level.tile_size, World.level.tile_size)
			elif w == 0 && h == 0: # top left
				sprite.texture.region.position = Vector2(0.0, 0.0)
			elif w == _width-1 && h == 0: # top right
				sprite.texture.region.position = Vector2(World.level.tile_size * 2, 0.0)
			elif w > 0 && w < _width-1 && h == 0: # top center
				sprite.texture.region.position = Vector2(World.level.tile_size, 0.0)
			elif w == 0 && h > 0 && h < _height-1: # center left
				sprite.texture.region.position = Vector2(0.0, World.level.tile_size)
			elif w == _width-1 && h > 0 && h < _height-1: # center right
				sprite.texture.region.position = Vector2(World.level.tile_size * 2, World.level.tile_size)
			elif w == 0 && h == _height-1: # bottom left
				sprite.texture.region.position = Vector2(0.0, World.level.tile_size * 2)
			elif w == _width-1 && h == _height-1: # bottom right
				sprite.texture.region.position = Vector2(World.level.tile_size * 2, World.level.tile_size * 2)
			elif w > 0 && w < _width-1 && h == _height-1: # bottom center
				sprite.texture.region.position = Vector2(World.level.tile_size, World.level.tile_size * 2)
		
	# spikes
	for i in _width:
		var sprite : Sprite2D = Sprite2D.new()
		sprite.position = Vector2(i * World.level.tile_size, _height * World.level.tile_size)
		sprite.texture = AtlasTexture.new()
		sprite.texture.atlas = _crusher_texture
		sprite.texture.region = Rect2i(
			Vector2(0.0, 48.0), Vector2.ONE * World.level.tile_size
		)
		_sprites_container.add_child(sprite)
	
	# colliders
	var half_tile : Vector2 = Vector2.ONE * World.level.tile_size / 2.0
	_collider.shape.size = Vector2(_width, _height) * World.level.tile_size
	_collider.position = -half_tile + _collider.shape.size / 2.0
	
	_hurtbox_collider.shape.size = Vector2(
		_width * World.level.tile_size,
		World.level.tile_size
	)
	_hurtbox_collider.position = -half_tile + Vector2(
		_hurtbox_collider.shape.size.x / 2.0,
		_height * World.level.tile_size + half_tile.y
	)
	
	queue_redraw()
