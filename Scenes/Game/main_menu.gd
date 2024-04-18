extends MarginContainer

@onready var _parallax_order : Array[Control] = [
	$Background/TextureRect,
	$Background/TextureRect2,
	$Background/TextureRect3,
#	$Menu
]
@onready var _main_menu_container : VBoxContainer = $Menu/MarginContainer/Main
@onready var _settings_container : VBoxContainer = $Menu/MarginContainer/Settings
@onready var _volume_slider : HSlider = $Menu/MarginContainer/Settings/VBoxContainer/Volume

@onready var _hovered_sfx : AudioStreamPlayer = $Hovered
@onready var _pressed_sfx : AudioStreamPlayer = $Pressed

const _bg_parallax_factor : float = 0.01
const _master_bus_idx : int = 0


func _input(event : InputEvent):
	if event is InputEventMouseMotion:
		var screen_center : Vector2 = get_tree().root.size / 2.0
		var mouse_dist_from_center : Vector2 =\
			event.global_position - screen_center
		
		for i in _parallax_order.size():
			var control : Control = _parallax_order[i]
			control.position =\
				-mouse_dist_from_center * _bg_parallax_factor * (i+1)

func _on_play_pressed():
	_pressed_sfx.play()
	# for now just move to testing scene
	SceneManager.change_scene("res://Scenes/Game/Levels/testing.tscn")

func _on_settings_pressed():
	_pressed_sfx.play()
	_main_menu_container.hide()
	_settings_container.show()

func _on_quit_pressed():
	get_tree().quit()

func _on_volume_changed():
	AudioServer.set_bus_volume_db(
		_master_bus_idx,
		_volume_slider.value
	)

func _on_settings_done_pressed():
	_pressed_sfx.play()
	_main_menu_container.show()
	_settings_container.hide()

func _on_button_hovered():
	_hovered_sfx.play()
