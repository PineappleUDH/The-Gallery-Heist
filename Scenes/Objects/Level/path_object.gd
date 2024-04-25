extends Path2D
class_name PathObject

@export var _loop : bool = true
@export var _speed_per_sec : float = 80.0

@onready var _path : PathFollow2D = $PathFollow2D


func _ready():
	# _speed is in pixel rather than ratio in order to easily control it and so
	# that chaning path length doesn't affect it
	var speed_to_time : float = curve.get_baked_length() / _speed_per_sec
	
	var move_tween : Tween = create_tween().set_loops()
	if _loop:
		move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		move_tween.tween_property(_path, "progress_ratio", 1.0, speed_to_time / 2.0)
		move_tween.tween_property(_path, "progress_ratio", 0.0, speed_to_time / 2.0)
	else:
		move_tween.tween_property(_path, "progress_ratio", 1.0, speed_to_time).from(0.0)
