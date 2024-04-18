extends Line2D

@onready var _path_follow : PathFollow2D = $"../PathFollow2D"

func _process(delta):
	set_point_position(1, _path_follow.position)
