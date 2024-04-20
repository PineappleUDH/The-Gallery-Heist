extends MarginContainer

@onready var _hovered_sfx : AudioStreamPlayer = $Hovered
@onready var _pressed_sfx : AudioStreamPlayer = $Pressed


func _input(event : InputEvent):
	if event.is_action_pressed("pause"):
		_set_pause(!get_tree().paused)

func _exit_tree():
	# in case of quiting while paused
	get_tree().paused = false

func _on_resume_pressed():
	_pressed_sfx.play()
	_set_pause(false)

func _on_restart_pressed():
	_pressed_sfx.play()
	SceneManager.restart_scene()

func _on_quit_pressed():
	_pressed_sfx.play()
	# main menu
	SceneManager.change_scene("res://Scenes/Game/main_menu.tscn")

func _set_pause(pause : bool):
	if pause:
		get_tree().paused = true
		show()
	else:
		get_tree().paused = false
		hide()

func _on_mouse_entered():
	_hovered_sfx.play()
