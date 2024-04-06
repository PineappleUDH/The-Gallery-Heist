class_name GameplayRecorder
extends Node

# to use this system toggle _record_on_game_start on to record gameplay.
# or use the gameplay_recorder_interface plugin to select a file that'd be played.

# Record file:
# file name must follow the pattern: "InputRecord (yy-mm-dd hh-mm-ss)".json
# json file format:
# "category" a category identifier for grouping records of similar purpose ("alpha testing" for example)
# "length" the time gamplay_recorder was recording for
# "input" an array of dictionaries each representing a single input. each input event has:
#   "type" type of input see _InputType
#   "time" timestamp of when the input was sent
#   type specific variables and their values

enum _RecorderState {none, recording, replaying}
enum _InputType {key, mouse_btn, mouse_motion, joypad_btn, joypad_motion}

@onready var _mouse_blocker : Control = $MouseBlocker
@onready var _record_notice : PanelContainer = $Panels/Control/RecordNotice
@onready var _status_panel : MarginContainer = $Panels/Control/Status
@onready var _status_label : Label = $Panels/Control/Status/PanelContainer/Label

# settings
const _record_on_game_start : bool = false # toggle on to start recording on game start
const _compress_recording_size : bool = false # only saves some input data to file to reduse its size
const _record_catergory_name : String = "Alpha Tests 2" # a generic name to be assigned to the record files. the plugin uses these categories for sorting

var _state : _RecorderState = _RecorderState.none
var _file : FileAccess

# recording
const _record_file_name : String = "InputRecord"
var _record_data : Dictionary
var _record_output_path : String

# replaying
const _replay_file_path : String = "res://addons/gameplay_recorder_interface/replay_file.txt"
var _replay_timming_thread : Thread
var _replay_data : Dictionary
var _next_replay_input_idx : int = 0
const _stop_replaying_flash_times : int = 8
const _stop_replaying_flash_delay : float = 0.2


# TODO: more error checking
func _ready():
	_record_notice.hide()
	_status_panel.hide()
	
	var is_standalone : bool = OS.has_feature("standalone")
	if _record_on_game_start:
		# record gameplay
		_record_notice.show()
		_mouse_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		
		if is_standalone:
			# when running outside the editor place records next to exe
			_record_output_path = OS.get_executable_path().get_base_dir()
		else:
			# when running in editor place in addon records folder
			_record_output_path = "res://addons/gameplay_recorder_interface/records/"
			if DirAccess.dir_exists_absolute(_record_output_path) == false:
				DirAccess.make_dir_recursive_absolute(_record_output_path)
		
	elif is_standalone == false && FileAccess.file_exists(_replay_file_path):
		var file : FileAccess = FileAccess.open(_replay_file_path, FileAccess.READ)
		var record_file_path : String = file.get_as_text()
		file.close()
		
		if record_file_path.is_empty() == false && FileAccess.file_exists(record_file_path):
			# replay gameplay. the file to replay is written in _replay_file_path
			_file = FileAccess.open(record_file_path, FileAccess.READ)
			if _file == null:
				push_error("Something went wrong.. " + str(FileAccess.get_open_error()) + ". Gameplay recorder will not replay")
				_state = _RecorderState.none
			
			else:
				_replay_data = JSON.parse_string(_file.get_as_text())
				_status_panel.show()
				_status_label.text = "Replaying. Don't interfere, don't even move your mouse."
				_state = _RecorderState.replaying
				Input.warp_mouse(get_tree().root.size / 2.0)
				
				# handle timming in a thread for more accuracy
				_replay_timming_thread = Thread.new()
				_replay_timming_thread.start(_replay_record_input, Thread.PRIORITY_HIGH)
			
			_file.close()

func _notification(what : int):
	if what == NOTIFICATION_WM_CLOSE_REQUEST && _state == _RecorderState.recording:
		_record_data["length"] = _get_time_s()
		_file.store_string(JSON.stringify(_record_data, "\t"))
		_file.close()

# TODO: replay isn't 100% accurate, it has some small time offsets that aren't noticeable
#       but sometimes that small offset makes the difference between landing or missing a platform
#       I'll have to look more deeply into it once v1.0 is done
func _replay_record_input():
	while _state == _RecorderState.replaying:
		var next_input : Dictionary = _replay_data["input"][_next_replay_input_idx]
		if Time.get_ticks_msec() / 1000.0 >= float(next_input["time"]):
			var input
			match int(next_input["type"]):
				_InputType.key:
					input = InputEventKey.new()
				_InputType.mouse_btn:
					input = InputEventMouseButton.new()
				_InputType.mouse_motion:
					input = InputEventMouseMotion.new()
				_InputType.joypad_btn:
					input = InputEventJoypadButton.new()
				_InputType.joypad_motion:
					input = InputEventJoypadMotion.new()
			
			for data : String in next_input["data"].keys():
				input.set(data, next_input["data"][data])
			
			# mark our input as "artificial", so we can ignore it in _input
			input.set_meta("artificial", true)
			Input.parse_input_event.call_deferred(input)
			
			_next_replay_input_idx += 1
			if _next_replay_input_idx == _replay_data["input"].size():
				# replay done, allow user to continue normally
				_stop_replaying.call_deferred()
				break

func _input(event : InputEvent):
	if _state == _RecorderState.recording:
		var type : _InputType
		var data : Dictionary
		if event is InputEventKey:
			type = _InputType.key
			data = {"pressed":event.pressed, "keycode":event.keycode,
			"key_label":event.key_label, "physical_keycode":event.physical_keycode,
			"unicode":event.unicode}
			
			if _compress_recording_size == false:
				data.merge({
					"echo":event.echo, "ctrl_pressed":event.ctrl_pressed, "alt_pressed":event.alt_pressed,
					"shift_pressed":event.shift_pressed, "meta_pressed":event.meta_pressed,
					
				})
			
		elif event is InputEventMouseButton:
			type = _InputType.mouse_btn
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
			
		# TODO: can event.relative be useless if the screen resolution where the game was recorded is different
		#       than where it's replayed? need testing. if so scale the relative value by the difference in
		#       resolution. would people be okay with the record containing their screen resolution? what a pain
		elif event is InputEventMouseMotion:
			type = _InputType.mouse_motion
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
			type = _InputType.joypad_btn
			data = {
				"button_index":event.button_index, "pressed":event.pressed, "pressure":event.pressure
			}
			
			if _compress_recording_size == false:
				data.merge({
					"device":event.device
				})
			
		elif event is InputEventJoypadMotion:
			type = _InputType.mouse_motion
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
		
		_record_data["input"].append(
			{"type":type, "time":_get_time_s(), "data":data}
		)
	
	elif _state == _RecorderState.replaying:
		if event is InputEventMouseMotion && event.relative == Vector2.ZERO:
			# ignore the initial empty motion events, no clue why but at the project start
			# 3 or 4 events of this type will fire with 0 relative motion
			return
		
		if event.get_meta("artificial", false) == true:
			# this is just our event that we pushed in _replay_record_input
			return
		
		# player messed with input, abort
		_stop_replaying()

func _get_time_s() -> String:
	return str(float(Time.get_ticks_msec()) / 1000.0)

func _stop_replaying():
	assert(_state == _RecorderState.replaying)
	
	_state = _RecorderState.none
	_status_panel.hide()
	_replay_timming_thread.wait_to_finish()
	
	for i in _stop_replaying_flash_times:
		await get_tree().create_timer(_stop_replaying_flash_delay).timeout
		_status_panel.visible = !_status_panel.visible

func _on_record_notice_closed(is_yes_pressed : bool):
	_record_notice.hide()
	_mouse_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# NOTE: sometimes users will take a while before aggreeing to start recording. by the time yes is
	#       pressed Time.get_ticks_msec will be high leading to the first input being recorded after much delay
	#       there isn't much to be done about this since trying to shrink the starting time could
	#       lead to inconsistent results between replay sessions
	if is_yes_pressed:
		# begin recording
		var time_data : Dictionary = Time.get_datetime_dict_from_system()
		var time_string : String = "%d-%02d-%02d %02d-%02d-%02d" %\
			[time_data["year"] - 2000, time_data["month"],
			time_data["day"], time_data["hour"],
			time_data["minute"], time_data["second"]]
		
		_file = FileAccess.open(
			_record_output_path + _record_file_name + " (" + time_string + ").json",
			FileAccess.WRITE
		)
		if _file == null:
			push_error("Something went wrong.. " + str(FileAccess.get_open_error()) + ". Gameplay recorder will not work")
			_state = _RecorderState.none
			return
		
		_state = _RecorderState.recording
		_status_panel.show()
		_status_label.text = "Recording."
		Input.warp_mouse(get_tree().root.size / 2.0)
		_record_data["category"] = _record_catergory_name
		_record_data["input"] = []
	
	else:
		# don't record
		_state = _RecorderState.none
