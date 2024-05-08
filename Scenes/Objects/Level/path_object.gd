extends Path2D
class_name PathObject

## makes platform move back and forth between start and end point, when off the platform will teleport back to the start after reahcing the end
@export var _loop : bool = true
## use smoothness when the platform reaches the end,
@export var _smooth_follow : bool = true
## speed per second :)
@export var _speed_per_sec : float = 80.0
## a delay before the platform starts moving
@export var _delay_time : float = 0.0

@onready var _delay = $Delay
@onready var _path : PathFollow2D = $PathFollow2D

func _ready():
	_delay.start(_delay_time)

func _on_delay_timeout():
		# _speed is in pixel rather than ratio in order to easily control it and so
	# that chaning path length doesn't affect it
	var speed_to_time : float = curve.get_baked_length() / _speed_per_sec
	
	var move_tween : Tween = create_tween().set_loops()
	if _loop:
		if _smooth_follow:
			move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		move_tween.tween_property(_path, "progress_ratio", 1.0, speed_to_time / 2.0)
		move_tween.tween_property(_path, "progress_ratio", 0.0, speed_to_time / 2.0)
	else:
		move_tween.tween_property(_path, "progress_ratio", 1.0, speed_to_time).from(0.0)
