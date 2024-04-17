extends Path2D

@export var _loop : bool = true
@export var _speed : float = 2.0
@export var _speed_scale : float = 1.0

@onready var _path : PathFollow2D = $PathFollow2D
@onready var _animation : AnimationPlayer = $AnimationPlayer


func _ready():
	if not _loop:
		_animation.play("move")
		_animation.speed_scale = _speed_scale
		set_process(false)

func _process(delta : float):
	_path.progress += _speed
