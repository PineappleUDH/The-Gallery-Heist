extends "res://Scenes/Objects/Level/path_object.gd"

@onready var _path_follow : PathFollow2D = $PathFollow2D
@onready var _rope : Line2D = $rope

func _ready():
	super._ready()
	_rope.add_point(Vector2.ZERO)
	_rope.add_point(Vector2.ZERO)

func _process(delta : float):
	_rope.set_point_position(1, _path_follow.position)
