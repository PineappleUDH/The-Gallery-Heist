extends MarginContainer


func _input(event : InputEvent):
	if event.is_action_pressed("pause"):
		_set_pause(!get_tree().paused)

func _on_resume_pressed():
	_set_pause(false)

func _on_quit_pressed():
	# main menu
	SceneManager.change_scene("res://Scenes/Game/main_menu.tscn")

func _set_pause(pause : bool):
	if pause:
		get_tree().paused = true
		show()
	else:
		get_tree().paused = false
		hide()
