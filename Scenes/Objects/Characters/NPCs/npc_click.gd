extends "res://Scenes/Objects/Characters/NPCs/npc.gd"


var _first_meeting : bool = true
var _disable : bool = false
var _opening_lines : Array[Dialogue] = [
	Dialogue.create(
		"Oh, hey, you're that [color=#1ebc73]Saul[/color] guy? 
		
		You're even balder than I thought you'd be",
		"Click"
	),
	Dialogue.create(
		"Oh wow, a talking mouse?",
		"Saul"
	),
	Dialogue.create(
		"Yeah, the names [color=#4d9be6]Click[/color], we're gonna be in this game together!",
		"Click"
	),
	Dialogue.create(
		"So you're [color=#4d9be6]Click, The Mouse[/color]? That's cute",
		"Saul"
	),
	Dialogue.create(
		"[shake]uhh yeah..[/shake] you can just call me [color=#4d9be6]Click[/color]",
		"Click"
	),
	Dialogue.create(
		"[i]Anyway,[/i] good luck in there!",
		"Click"
	),
	Dialogue.create(
		"[color=#f9c22b]CONSTRUCTION STATUS:[/color] 
		
		[color=#e83b3b]X=UNDER CONSTRUCTION[/color]
		[color=#239063]O=COMPLETE[/color]
		
		[color=#239063]GREEN PATH[/color] [color=#e83b3b][X][/color]
		[color=#4d9be6]BLUE PATH[/color] [color=#e83b3b][X][/color]
		[color=#e83b3b]RED PATH[/color] [color=#239063][O][/color]"
	)
]

@onready var _trigger_dialogue = $TriggerDialogue

func _process(delta):
	pass

func _on_interaction_area_body_entered(body : Node2D):
	if _disable == false:
		match _first_meeting:
			true:
				World.level.dialogue_player.play_dialogue(_opening_lines, true)
			false:
				_trigger_dialogue.monitoring = true
				_disable = true


func _on_interaction_area_body_exited(body):
	if body is Player and _first_meeting == true:
		_first_meeting = false
