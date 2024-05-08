@tool
class_name TriggerMusic
extends "res://Scenes/Objects/Triggers/trigger.gd"

enum _TriggerType {scedule_music, stop_music}

## how this trigger affects the music in the level
@export var _trigger_type : _TriggerType = _TriggerType.scedule_music :
	set(value):
		_trigger_type = value
		notify_property_list_changed()

@export_group("New Music")
## the music file to play, drag and drop from the FileSystem tab
@export var _music : AudioStreamOggVorbis
## the beat per minute of the music, used to smoothly transition between one music and another when "is_sudden" is off
@export var _bpm : float = 0.0
## if true the music will play immediately, otherwise it will play at a transition point of the previously playing music
@export var _is_sudden : bool = false
## the volume of the music
@export var _volume : float = 0.0


func apply_music():
	if _trigger_type == _TriggerType.scedule_music:
		if World.level.music_player.is_music_already_playing(_music) == false:
			World.level.music_player.schedule_music(_music, _bpm, _is_sudden, _volume)
		
	elif _trigger_type == _TriggerType.stop_music:
		World.level.music_player.stop_music()

func _player_entered():
	apply_music()

func _validate_property(property : Dictionary):
	match property["name"]:
		"_music", "_bpm", "_is_sudden", "_volume":
			if _trigger_type == _TriggerType.stop_music:
				property["usage"] = PROPERTY_USAGE_NO_EDITOR
