@tool
extends "res://Scenes/Objects/Affordances/path_object.gd"

@onready var _rope : Line2D = $rope

func _ready():
	if Engine.is_editor_hint(): return
	
	super._ready()
	_rope.add_point(Vector2.ZERO)
	_rope.add_point(Vector2.ZERO)

func _process(delta : float):
	if Engine.is_editor_hint(): return
	
	_rope.set_point_position(1, _path_follow.position)
