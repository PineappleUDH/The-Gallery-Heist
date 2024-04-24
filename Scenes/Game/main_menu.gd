extends MarginContainer

@onready var _parallax_order : Array[Array] = [
	[$Background/Background],
	[$"Background/11", $"Background/12", $"Background/13"],
	[$"Background/21", $"Background/22", $"Background/23", $"Background/24", $"Background/25", $"Background/26", $"Background/27"],
	[$"Background/31", $"Background/32", $"Background/33", $"Background/34"]
]
@onready var _menu : PanelContainer = $Menu
@onready var _main_options_container : VBoxContainer = $Menu/MarginContainer/Main
@onready var _settings_container : VBoxContainer = $Menu/MarginContainer/Settings
@onready var _controls_container : VBoxContainer = $Menu/MarginContainer/Controls
@onready var _volume_slider : HSlider = $Menu/MarginContainer/Settings/VBoxContainer/Volume
@onready var _keybinds_container : VBoxContainer = $Menu/MarginContainer/Controls/KeybindsContainer

@onready var _hovered_sfx : AudioStreamPlayer = $Hovered
@onready var _pressed_sfx : AudioStreamPlayer = $Pressed

const _single_keybind_ui_scene : PackedScene = preload("res://Scenes/Objects/single_keybind.tscn")
var _keybinds_file_path = "user://keybinds.json"

var _parallax_starting_pos : Array[Array]
const _popup_tween_time : float = 0.5
const _popup_tween_menu_time : float = 1.5

const _bg_parallax_factor : float = 0.015
const _master_bus_idx : int = 0


func _ready():
	# load saved keybinds
	if FileAccess.file_exists(_keybinds_file_path):
		for action in _get_user_actions():
			InputMap.erase_action(action)
		
		var file : FileAccess = FileAccess.open(_keybinds_file_path, FileAccess.READ)
		var json_data : Array = JSON.parse_string(file.get_as_text())
		file.close()
		
		if json_data == null:
			push_error("keybinds file is corrupted and will be ignored")
		else:
			for data : Dictionary in json_data:
				InputMap.add_action(data["action"])
				for event : String in data["events"]:
					# convert string "[1, 2, 3..]" to PackedByteArray
					var chars_array : PackedStringArray =\
						event.substr(1, event.length()-2).split(",", false)
					var byte_array : PackedByteArray
					for char_ in chars_array: byte_array.append(int(char_))
					
					InputMap.action_add_event(data["action"], bytes_to_var_with_objects(byte_array))
	
	# save original parallax positions
	await sort_children
	for i in _parallax_order.size():
		_parallax_starting_pos.append([])
		for j in _parallax_order[i].size():
			_parallax_starting_pos[i].append(_parallax_order[i][j].global_position)
	
	# popup order
	var tween : Tween = create_tween()
	for i in _parallax_order.size():
		for j in _parallax_order[i].size():
			if j == 1: tween.set_parallel(true)
			_parallax_order[i][j].modulate.a = 0.0
			tween.tween_property(_parallax_order[i][j], "modulate:a", 1.0, _popup_tween_time).from(0.0)
		tween.set_parallel(false)
	
	_menu.modulate.a = 0.0
	tween.tween_property(_menu, "modulate:a", 1.0, _popup_tween_menu_time).from(0.0)

func _input(event : InputEvent):
	if event is InputEventMouseMotion && _parallax_starting_pos:
		var screen_center : Vector2 = get_tree().root.size / 2.0
		var mouse_dist_from_center : Vector2 =\
			event.global_position - screen_center
		
		for i in _parallax_order.size():
			for j in _parallax_order[i].size():
				var control : Control = _parallax_order[i][j]
				control.global_position = _parallax_starting_pos[i][j] +\
					-mouse_dist_from_center * _bg_parallax_factor * (i+1)

func _on_play_pressed():
	_pressed_sfx.play()
	# for now just move to testing scene
	SceneManager.change_scene("res://Scenes/Game/Levels/testing.tscn")

func _on_settings_pressed():
	_pressed_sfx.play()
	_main_options_container.hide()
	_settings_container.show()

# TODO: prevent using the same key for more than 1 action
#       also allow reseting to default input map by saving map before applying changes
func _on_controls_pressed():
	_pressed_sfx.play()
	_main_options_container.hide()
	_controls_container.show()
	
	# load keybinds from InputMap
	for keybind in _keybinds_container.get_children(): keybind.queue_free()
	
	for action : StringName in _get_user_actions():
		var keybind : Control = _single_keybind_ui_scene.instantiate()
		var bind_name : String = action
		var bind1 : InputEventWithModifiers
		var bind2 : InputEventWithModifiers
		
		for event : InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey || event is InputEventMouse:
				if bind1 == null: bind1 = event
				elif bind2 == null: bind2 = event
				else: assert(false, "Keybinds only support 2 keys, one of the Inputs in the InputMap used more than 2 keys (mouse buttons also count)")
		
		_keybinds_container.add_child(keybind)
		keybind.setup(bind_name, bind1, bind2)

func _on_quit_pressed():
	get_tree().quit()

func _on_settings_done_pressed():
	_pressed_sfx.play()
	_main_options_container.show()
	_settings_container.hide()

func _on_controls_done_pressed():
	_pressed_sfx.play()
	_main_options_container.show()
	_controls_container.hide()
	
	# apply keybinds
	for keybind in _keybinds_container.get_children():
		var data : Dictionary = keybind.get_data()
		var action_name : String = data["name"]
		
		# clear key and mouse button events
		for event : InputEvent in InputMap.action_get_events(action_name):
			if event is InputEventKey || event is InputEventMouseButton:
				InputMap.action_erase_event(action_name, event)
		
		if data["bind1"] != null:
			InputMap.action_add_event(action_name, data["bind1"])
		if data["bind2"] != null:
			InputMap.action_add_event(action_name, data["bind2"])
	
	# save keybinds to file
	var file : FileAccess = FileAccess.open(_keybinds_file_path, FileAccess.WRITE)
	var json_data : Array[Dictionary]
	for action : StringName in _get_user_actions():
		json_data.append({"action":action, "events":[]})
		for event : InputEvent in InputMap.action_get_events(action):
			json_data[-1]["events"].append(var_to_bytes_with_objects(event))
	
	file.store_string(JSON.stringify(json_data, "\t"))
	file.close()

func _on_controls_cancel_pressed():
	_pressed_sfx.play()
	_main_options_container.show()
	_controls_container.hide()

func _on_volume_changed():
	AudioServer.set_bus_volume_db(
		_master_bus_idx,
		_volume_slider.value
	)

func _on_fullscreen_toggled(toggled_on : bool):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _get_user_actions() -> Array[StringName]:
	var actions : Array[StringName]
	for action in InputMap.get_actions():
		# ignore built-in actions which always start with "ui_"
		if action.begins_with("ui_") == false:
			actions.append(action)
	
	return actions

func _on_button_hovered():
	_hovered_sfx.play()
