extends Area2D

var _first_meeting : bool = true




func _on_body_entered(body):
	if _first_meeting == true :
		World.level.dialogue_player.play_dialogue()
