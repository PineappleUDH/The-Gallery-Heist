extends Area2D


func _on_body_entered(body : Node2D):
	if body is Player:
		_player_entered()

# override
func _player_entered():
	return
