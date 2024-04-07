extends Node2D

@onready var _spawn_timer : Timer = $SpawnTimer
@onready var _particles : GPUParticles2D = $GPUParticles2D

var _sprites : Array[Dictionary] # {sprite, time}

var _flip_h : bool
const _sprite_lifetime : float = 0.6
const _color_ramp : Array[Color] = [
	Color.WHITE, Color("#0b8a8f"), Color.BLACK
]


func _ready():
	set_process(false)

func _process(delta : float):
	if _sprites.is_empty(): set_process(false)
	
	for i : int in range(_sprites.size()-1, -1, -1): # backward iteration so erasing doesn't break order
		var dict : Dictionary = _sprites[i]
		
		# lifetime
		dict["timer"] -= delta
		if dict["timer"] <= 0.0:
			dict["sprite"].queue_free()
			_sprites.erase(dict)
			continue
		
		var sprite : Sprite2D = dict["sprite"]
		sprite.scale = Vector2.ONE * remap(dict["timer"], _sprite_lifetime, 0.0, 1.2, 0.0)
		
		# color ramps, we map lifetime to _color_ramp array. use the number as index and decimal as lerp value
		var ramp_array_value : float = remap(dict["timer"], _sprite_lifetime, 0.0, 0.0, _color_ramp.size())
		var ramp_idx : int = floor(ramp_array_value)
		var ramp_next_idx : int = ramp_idx + 1
		if ramp_next_idx < _color_ramp.size():
			sprite.modulate = lerp(
				_color_ramp[ramp_idx], _color_ramp[ramp_next_idx], ramp_array_value - ramp_idx)
		else:
			sprite.modulate = _color_ramp[ramp_idx]

func set_active(active : bool, flip_h : bool = false):
	if active:
		_spawn_timer.start()
		_flip_h = flip_h
		
		var facing : Vector2 = World.level.player.get_facing().normalized()
		_particles.process_material.direction = -Vector3(facing.x, facing.y, 0.0)
		_particles.restart()
	else:
		_spawn_timer.stop()

func _on_spawn_timer_timeout():
	var sprite : Sprite2D = Sprite2D.new()
	sprite.texture = preload("res://Resources/Textures/SaulSprites/dashsmear2 (AddinSachen).png")
	sprite.global_position = self.global_position
	sprite.flip_h = _flip_h
	get_tree().current_scene.add_child(sprite)
	
	_sprites.append({"sprite":sprite, "timer":_sprite_lifetime})
	set_process(true)
