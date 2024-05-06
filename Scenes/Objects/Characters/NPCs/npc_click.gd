extends "res://Scenes/Objects/Characters/NPCs/npc.gd"


var _first_meeting : bool = true
var _opening_lines : Array[Dialogue] = [
	Dialogue.create(
		"Oh, hey, you're that Saul guy? You're even balder than I thought you'd be",
		"Click"
	),
	Dialogue.create(
		"And now I'm being heckled by a talking mouse, lovely",
		"Saul"
	),
	Dialogue.create(
		"Just having some fun with you, Saul, good luck in the trial!",
		"Click"
	),
	Dialogue.create(
		"CONSTRUCTION STATUS: 
			X = UNDER CONSTRUCTION
			O = COMPLETE
		GREEN [X]
		BLUE [X]
		RED [O]"
	)
]

@onready var _trigger_dialogue = $TriggerDialogue

func _process(delta):
	pass

func _on_interaction_area_body_entered(body : Node2D):
	if _first_meeting == true:
		World.level.dialogue_player.play_dialogue(_opening_lines, true)


func _on_interaction_area_body_exited(body):
	if body is Player and _first_meeting == true:
		_trigger_dialogue.monitoring = true
		_first_meeting = false
