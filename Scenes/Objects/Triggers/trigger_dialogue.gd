extends "res://Scenes/Objects/Triggers/trigger.gd"

@export var _sequence : Array[Dialogue] # TODO: array of sequences instead
@export var _is_blocking : bool = false
@export var _randomize_order : bool = false
@export var _play_each_dialogue_once : bool = true

var _last_ordered_dialogue_idx : int = -1

# override
func _player_entered():
	if _sequence.is_empty(): return
	
	var dialogue_idx : int
	if _randomize_order:
		dialogue_idx = randi_range(0, _sequence.size()-1)
	else:
		if _last_ordered_dialogue_idx != -1:
			dialogue_idx = (_last_ordered_dialogue_idx + 1) % _sequence.size()
		else:
			dialogue_idx = 0
	
	World.level.dialogue_player.play_dialogue([_sequence[dialogue_idx]] as Array[Dialogue], _is_blocking)
	if _play_each_dialogue_once:
		# delete dialogue after being used
		_sequence.remove_at(dialogue_idx)
	else:
		_last_ordered_dialogue_idx = dialogue_idx
