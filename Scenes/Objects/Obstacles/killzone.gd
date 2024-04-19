extends Area2D


func _on_body_entered(body : Node2D):
	if body is Character:
		# die muhahahaha
		body.take_damage(0, Vector2.ZERO, true)
