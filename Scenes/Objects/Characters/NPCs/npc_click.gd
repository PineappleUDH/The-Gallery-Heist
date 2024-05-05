extends "res://Scenes/Objects/Characters/NPCs/npc.gd"


var _first_meeting : bool = true

func _on_interaction_area_body_entered(body : Node2D):
	pass
#	if _first_meeting == true:
#		_first_meeting = false
#		World.level.dialogue_player.play_dialogue()
