class_name LevelCamera
extends Camera2D

enum CameraState {idle, follow}
enum ShakeLevel {low, medium, high}

@export var _starting_trigger : TriggerCamera

@onready var _shake_timer : Timer = $ShakeTimer

var _curr_state : CameraState = CameraState.follow
const _zoom_speed : float = 1.6
var _target_zoom : Vector2 = Vector2.ONE
var _target_position : Vector2
const _speed : float = 120.0
const _distance_speed_factor : Vector2 = Vector2(0.022, 0.05)

const _player_velocity_factor : Vector2 = Vector2(0.7, 0.0)
const _player_velocity_max_offset : float = 140.0
var _axis_bounds : Dictionary

const _shake_data : Dictionary = {
	ShakeLevel.low:   {"max_offset":1.5},
	ShakeLevel.medium:{"max_offset":4.0},
	ShakeLevel.high:  {"max_offset":9.0}
}
var _curr_shake_level : ShakeLevel

var _player_y_look_direction : int = 0
const _player_y_look_offset : float = 80.0


func _ready():
	await get_tree().process_frame # wait for World.level to be set
	World.level.player.respawned.connect(_on_player_respawned)
	
	if _starting_trigger:
		_starting_trigger.apply_camera_state()

func _process(delta : float):
	var player : Player = World.level.player
	# update zoom
	if zoom != _target_zoom:
		zoom.x = move_toward(zoom.x, _target_zoom.x, _zoom_speed * delta)
		zoom.y = move_toward(zoom.y, _target_zoom.y, _zoom_speed * delta)
	
	# calc target_position
	var target_position : Vector2
	if _curr_state == CameraState.idle:
		target_position = _target_position
		
	elif _curr_state == CameraState.follow:
		var velocity_offset : Vector2 = player.velocity.abs() * _player_velocity_factor
		velocity_offset.x = min(velocity_offset.x, _player_velocity_max_offset)
		velocity_offset.y = min(velocity_offset.y, _player_velocity_max_offset)
		
		target_position.x = player.global_position.x + sign(player.velocity.x) * (velocity_offset.x)
		target_position.y = player.global_position.y + sign(player.velocity.y) * (velocity_offset.y)
	
	if _player_y_look_direction:
		target_position.y += _player_y_look_offset * _player_y_look_direction
	
	# bounds, clamp camera edges rather than camera center
	var camera_half_size : Vector2 = (get_viewport_rect().size * zoom) / 2.0
	if _axis_bounds.has("x"):
		target_position.x = clamp(
			target_position.x,
			min(_axis_bounds["x"][0] + camera_half_size.x, _axis_bounds["x"][1]),
			max(_axis_bounds["x"][1] - camera_half_size.x, _axis_bounds["x"][0])
		)
	if _axis_bounds.has("y"):
		target_position.y = clamp(
			target_position.y,
			min(_axis_bounds["y"][0] + camera_half_size.y, _axis_bounds["y"][1]),
			max(_axis_bounds["y"][1] - camera_half_size.y, _axis_bounds["y"][0])
		)
	
	# calc camera speed. speed is influenced by the camera's distance to target
	# the further away the faster we move to catch up
	var distance : float = global_position.distance_to(target_position)
	var final_speed : Vector2 = Vector2(
		_speed * distance * _distance_speed_factor.x * delta,
		_speed * distance * _distance_speed_factor.y * delta
	)
	
	global_position = Vector2(
		move_toward(global_position.x, target_position.x, final_speed.x),
		move_toward(global_position.y, target_position.y, final_speed.y)
	)
	
	# shake
	if _shake_timer.is_stopped() == false:
		var max_offset : float = _shake_data[_curr_shake_level]["max_offset"]
		offset.x = randf_range(-max_offset, max_offset)
		offset.y = randf_range(-max_offset, max_offset)

func shake(shake_level : ShakeLevel, duration : float):
	_curr_shake_level = shake_level
	
	_shake_timer.wait_time = duration
	_shake_timer.start()

func player_look_offset(y_dir : int):
	_player_y_look_direction = y_dir

func set_target_zoom(zoom_ : Vector2):
	_target_zoom = zoom_

func set_axis_bound(is_x : bool, lock : Vector2):
	_axis_bounds["x" if is_x else "y"] = lock

func remove_axis_bound(is_x : bool):
	if is_x && _axis_bounds.has("x"): _axis_bounds.erase("x")
	elif is_x == false && _axis_bounds.has("y"): _axis_bounds.erase("y")

func set_state_idle(position_ : Vector2):
	_target_position = position_
	_curr_state = CameraState.idle

func set_state_follow():
	_curr_state = CameraState.follow

func _on_shake_timer_timeout():
	offset = Vector2.ZERO

func _on_player_respawned():
	global_position = World.level.player.global_position
	# TODO: we reapply initial state but that's not always accurate
	#       a trigger could change the camera state right before the checkpoint
	#       not sure what to do about that.. same thing for other types of triggers
	# a cheap solution would be to place an additional trigger collider on the checkpoint
	# so player hits it on respawn
	_starting_trigger.apply_camera_state()
