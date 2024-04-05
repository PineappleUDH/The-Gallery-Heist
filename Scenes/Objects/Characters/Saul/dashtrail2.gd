extends Sprite2D

var _direction
var _shrink_factor : float = 0.05

func _ready():
	_direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	print(_direction)
func _process(delta):
	if _direction.x > 0 or _direction.x < 0:
		scale.y -= 0.05
	if _direction.y > 0 or _direction.y < 0:
		scale.x -= 0.05
	
	if scale.y <= 0 or scale.x <= 0:
		queue_free()
