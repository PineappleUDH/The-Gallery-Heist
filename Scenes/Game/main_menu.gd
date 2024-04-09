extends MarginContainer

func _on_play_pressed():
	# for now just move to testing scene
	SceneManager.change_scene("res://Scenes/Game/Levels/testing.tscn")

func _on_settings_pressed():
	pass

func _on_quit_pressed():
	get_tree().quit()
