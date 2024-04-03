extends Node

@export var _starting_trigger : TriggerMusic

@onready var _stream_player : AudioStreamPlayer = $AudioStreamPlayer
@onready var _schedule_timer : Timer = $ScheduleTimer

var _scheduled_music : AudioStreamOggVorbis
var _bpm : float
var _volume : float


func _ready():
	if _starting_trigger:
		await get_tree().process_frame
		_starting_trigger.apply_music()

func schedule_music(
	music : AudioStreamOggVorbis, bpm : float,
	is_sudden : bool, volume : float = 0.0
):
	assert(music.loop, "Music must loop")
	
	if _scheduled_music:
		push_warning("Scheduling music while another scheduled music is yet to play, replacing scheduled music with new one")
	
	_scheduled_music = music
	_volume = volume
	
	if is_sudden || _stream_player.playing == false:
		_bpm = bpm
		_play_scheduled()
	else:
		# NOTE: this assumes 4/4 time signature
		var seconds_per_bar : float = (60.0 / _bpm) * 4.0
		var stream_pos : float = _stream_player.get_playback_position()
		# change music at next interval of 2 bars
		var time_to_next_music : float = (seconds_per_bar * 2.0) - fmod(stream_pos, (seconds_per_bar * 2.0))
		
		_bpm = bpm
		_schedule_timer.wait_time = time_to_next_music
		_schedule_timer.start()

func is_music_already_playing(_music : AudioStreamOggVorbis) -> bool:
	return _music == _scheduled_music || (_stream_player.playing && _music == _stream_player.stream)

func stop_music():
	_stream_player.stop()
	_schedule_timer.stop()
	_scheduled_music = null

func _play_scheduled():
	_stream_player.stream = _scheduled_music
	_scheduled_music = null
	
	_stream_player.volume_db = _volume
	_stream_player.play()

func _on_schedule_timer_timeout():
	if _scheduled_music:
		_play_scheduled()
