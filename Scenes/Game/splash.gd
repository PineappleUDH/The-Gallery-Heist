extends Control


func _input(event : InputEvent):
	if event.is_action_pressed("skip"):
		SceneManager.change_scene("res://Scenes/Game/main_menu.tscn")

func _on_music_finished():
	SceneManager.change_scene("res://Scenes/Game/main_menu.tscn")
