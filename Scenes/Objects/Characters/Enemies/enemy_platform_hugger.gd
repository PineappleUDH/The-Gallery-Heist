extends "res://Scenes/Objects/Characters/Enemies/enemy.gd"

@export var _start_moving_right : bool = true # TODO: editor hint of starting direction

@onready var _sprite : Sprite2D = $Sprite
@onready var _hole_ray : RayCast2D = $HoleRay
@onready var _wall_ray : RayCast2D = $WallRay

const _move_speed : float = 30.0
const _rotation_speed : float = 7.0
var _is_rotating : bool = false
var _rotation_target : float


func _ready():
	_max_health = 2
	_damage_cooldown_time = 1.0
	_health = _max_health
	_knockback = 0.0
	
	# setup facing direction, which won't change
	_direction.x = 1 if _start_moving_right else -1
	if _direction.x == -1:
		_hole_ray.position.x *= -1
		_wall_ray.position.x *= -1
		_wall_ray.target_position.x *= -1
		_sprite.flip_h = true
	
	_hole_ray.force_raycast_update()

func _physics_process(delta : float):
	if _is_rotating:
		velocity = Vector2.ZERO
		if _rotation_target > rotation:
			rotation = min(rotation + _rotation_speed * delta, _rotation_target)
		else:
			rotation = max(rotation - _rotation_speed * delta, _rotation_target)
		
		if is_equal_approx(rotation, _rotation_target):
			# enough rotating
			_is_rotating = false
	
	else:
		if is_on_floor() == false:
			# gravity
			velocity = -up_direction * _gravity
		else:
			velocity = _direction * _move_speed
			if _hole_ray.is_colliding() == false:
				# end of tile, rotate
				_is_rotating = true
				var next_rot : float = PI/2.0 * (1 if _start_moving_right else -1)
				up_direction = up_direction.rotated(next_rot)
				_direction = _direction.rotated(next_rot)
				_rotation_target = fmod(rotation + next_rot, TAU)
			
			elif _wall_ray.is_colliding() && _wall_ray.get_collider() is TileMap:
				# wall, rotate
				_is_rotating = true
				var next_rot : float = PI/2.0 * (-1 if _start_moving_right else 1)
				up_direction = up_direction.rotated(next_rot)
				_direction = _direction.rotated(next_rot)
				_rotation_target = fmod(rotation + next_rot, TAU)
	
	move_and_slide()
