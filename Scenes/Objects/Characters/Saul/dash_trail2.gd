extends Node2D

@onready var _spawn_timer : Timer = $SpawnTimer
@onready var _particles : GPUParticles2D = $GPUParticles2D

var _sprites : Array[Dictionary] # {sprite, time}

const _sprite_lifetime : float = 0.6


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
		sprite.modulate.a = remap(dict["timer"], _sprite_lifetime, 0.0, 1.0, 0.0)

func set_active(active : bool):
	if active:
		_spawn_timer.start()
		
		var facing : Vector2 = World.level.player.get_facing().normalized()
		_particles.process_material.direction = -Vector3(facing.x, facing.y, 0.0)
		_particles.restart()
	else:
		_spawn_timer.stop()

func _on_spawn_timer_timeout():
	var sprite : Sprite2D = Sprite2D.new()
	sprite.texture = preload("res://Resources/Textures/SaulSprites/dashsmear (AddinSachen).png")
	sprite.global_position = self.global_position
	sprite.flip_h = World.level.player.velocity.x < 0.0
	get_tree().current_scene.add_child(sprite)
	
	_sprites.append({"sprite":sprite, "timer":_sprite_lifetime})
	set_process(true)
