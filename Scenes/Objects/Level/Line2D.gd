extends Line2D

@onready var _anchor = $"../../Anchor"
@onready var _path = $".."


func _ready():
	add_point(_anchor.position,0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	add_point(_path.global_position,1)
