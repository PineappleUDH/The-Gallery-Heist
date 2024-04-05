extends Node

# to use this system toggle _record_on_game_start on to record gameplay.
# or use the gameplay_recorder_interface plugin to select a file that'd be played.

# Record file format:
# file name must follow the pattern: "InputRecord (yy-mm-dd hh-mm-ss)".json
# json file format:
# "category" a category identifier for grouping records of similar purpose ("alpha testing" for example)
# "length" the time gamplay_recorder was recording for
# "input" an array of dictionaries each representing a single input. each input event has:
#   "type" type of input
#   "time" timestamp of when the input was sent
#   type specific variables and their values

enum _RecorderState {none, recording, replaying}

@onready var _notice : PanelContainer = $Notice/PanelContainer

# settings
const _record_on_game_start : bool = true
const _compress_recording_size : bool = false
const _record_catergory_name : String = "Alpha Tests 2" # a generic name to be assigned to the record files. the plugin uses these categories for sorting

var _state : _RecorderState = _RecorderState.none
var _file : FileAccess

# recording
const _recorded_file_name : String = "InputRecord"
var _recorded_data : Dictionary
var _record_output_path : String

# replaying
const _replay_file_path : String = "res://addons/gameplay_recorder_interface/replay_file.txt"
var _replay_data : Dictionary


# TODO: more error checking
func _ready():
	var is_standalone : bool = OS.has_feature("standalone")
	
	if _record_on_game_start:
		# record gameplay
		_state = _RecorderState.recording
		_notice.show()
		
		if is_standalone:
			# when running outside the editor place records next to exe
			_record_output_path = OS.get_executable_path().get_base_dir()
		else:
			# when running in editor place directly in addon folder
			_record_output_path = "res://addons/gameplay_recorder_interface/records/"
		
	elif is_standalone == false && FileAccess.file_exists(_replay_file_path):
		var file : FileAccess = FileAccess.open(_replay_file_path, FileAccess.READ)
		var record_file_path : String = file.get_as_text()
		file.close()
		
		if record_file_path.is_empty() == false && FileAccess.file_exists(record_file_path):
			# replay a record
			_file = FileAccess.open(record_file_path, FileAccess.READ)
			if _file == null:
				push_error("Something went wrong.. " + str(FileAccess.get_open_error()) + ". Gameplay recorder will not replay")
				_state = _RecorderState.none
			
			else:
				_replay_data = JSON.parse_string(_file.get_as_text())
				_state = _RecorderState.replaying

func _notification(what : int):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		match _state:
			_RecorderState.recording:
				if _file:
					_recorded_data["length"] = _get_time_s()
					_file.store_string(JSON.stringify(_recorded_data, "\t"))
					_file.close()

func _process(delta : float):
	if _state == _RecorderState.replaying:
		Time.get_ticks_msec()
		#..

func _input(event : InputEvent):
	if _state == _RecorderState.recording && _file:
		var type : String
		var data : Dictionary
		if event is InputEventKey:
			type = "InputEventKey"
			data = {"pressed":event.pressed, "keycode":event.keycode,
			"key_label":event.key_label, "physical_keycode":event.physical_keycode,
			"unicode":event.unicode}
			
			if _compress_recording_size == false:
				data.merge({
					"echo":event.echo, "ctrl_pressed":event.ctrl_pressed, "alt_pressed":event.alt_pressed,
					"shift_pressed":event.shift_pressed, "meta_pressed":event.meta_pressed,
					
				})
			
		elif event is InputEventMouseButton:
			type = "InputEventMouseButton"
			data = {
				"button_index":event.button_index, "canceled":event.canceled, "double_click":event.double_click,
				"factor":event.factor, "pressed":event.pressed
			}
			
			if _compress_recording_size == false:
				data.merge({
					"device":event.device, "button_mask":event.button_mask, "global_position":event.global_position,
					"position":event.position
				})
				# modifiers are ignores (ctrl_pressed, alt_pressed, shift_pressed, meta_pressed)
			
		elif event is InputEventMouseMotion:
			type = "InputEventMouseMotion"
			data = {
				"relative":event.relative, "velocity":event.relative
			}
			# some vars are ignores (pen_inverted, pressure, tilt)
			
			if _compress_recording_size == false:
				data.merge({
					"device":event.device, "button_mask":event.button_mask, "global_position":event.global_position,
					"position":event.position
				})
				# modifiers are ignores (ctrl_pressed, alt_pressed, shift_pressed, meta_pressed)
			
		elif event is InputEventJoypadButton:
			type = "InputEventJoypadButton"
			data = {
				"button_index":event.button_index, "pressed":event.pressed, "pressure":event.pressure
			}
			
			if _compress_recording_size == false:
				data.merge({
					"device":event.device
				})
			
		elif event is InputEventJoypadMotion:
			type = "InputEventJoypadMotion"
			data = {
				"axis":event.axis, "axis_value":event.axis_value
			}
			
			if _compress_recording_size == false:
				data.merge({
					"device":event.device
				})
			
		else:
			# no need to save other events
			return
		
		_recorded_data["input"].append(
			{"type":type, "time":_get_time_s(), "data":data}
		)
	
	elif _state == _RecorderState.replaying:
		# TODO: player messed with input, abort
		pass

func _get_time_s() -> String:
	return str(float(Time.get_ticks_msec()) / 1000)

func _on_notice_ok_pressed():
	_notice.queue_free()
	
	# begin recording
	var time_data : Dictionary = Time.get_datetime_dict_from_system()
	var time_string : String = "%d-%02d-%02d %02d-%02d-%02d" %\
		[time_data["year"] - 2000, time_data["month"],
		time_data["day"], time_data["hour"],
		time_data["minute"], time_data["second"]]
	
	_file = FileAccess.open(
		_record_output_path + _recorded_file_name + " (" + time_string + ").json",
		FileAccess.WRITE
	)
	if _file == null:
		push_error("Something went wrong.. " + str(FileAccess.get_open_error()) + ". Gameplay recorder will not work")
		_state = _RecorderState.none
		return
	
	_recorded_data["category"] = _record_catergory_name
	_recorded_data["input"] = []

func _on_notice_stop_pressed():
	# don't record, player doesn't trust :(
	_state = _RecorderState.none
	_notice.queue_free()
