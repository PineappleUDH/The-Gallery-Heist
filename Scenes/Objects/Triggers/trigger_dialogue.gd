extends "res://Scenes/Objects/Triggers/trigger.gd"

# TODO: support for multiple dialogues. either played in random or set order

@export var _dialogue : Dialogue
@export var _play_once : bool = true

# override
func _player_entered():
	World.level.dialogue_player.play_dialogue(_dialogue)
	if _play_once:
		queue_free()
