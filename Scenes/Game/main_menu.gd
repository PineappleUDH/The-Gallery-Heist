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

@onready var _hovered_sfx : AudioStreamPlayer = $Hovered
@onready var _pressed_sfx : AudioStreamPlayer = $Pressed

var _parallax_starting_pos : Array[Array]
const _popup_tween_time : float = 0.5
const _popup_tween_menu_time : float = 1.5

const _bg_parallax_factor : float = 0.015
const _master_bus_idx : int = 0


func _ready():
	# save original positions
	await sort_children
	for i in _parallax_order.size():
		_parallax_starting_pos.append([])
		for j in _parallax_order[i].size():
			_parallax_starting_pos[i].append(_parallax_order[i][j].global_position)
	
	# show order
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

func _on_controls_pressed():
	_pressed_sfx.play()
	_main_options_container.hide()
	_controls_container.show()

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
	
	# apply controls and save to file

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

func _on_button_hovered():
	_hovered_sfx.play()
