extends AnimatedSprite2D

var _target_position : Vector2


func _ready():
	set_process(false)

func _process(delta : float):
	global_position = _target_position

func splash(at : Vector2):
	_target_position = at
	set_process(true)
	play("default")

func _on_animation_finished():
	set_process(false)
	play("empty")
