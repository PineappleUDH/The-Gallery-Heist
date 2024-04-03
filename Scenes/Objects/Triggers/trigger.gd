extends Area2D


# TODO: nothing in common for now, but eventually I'll make an addon
#       that help visualize triggers and what they do in editor



func _on_body_entered(body : Node2D):
	if body is Player:
		_player_entered()

# override
func _player_entered():
	return
