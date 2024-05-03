extends MarginContainer

@onready var _hovered_sfx : AudioStreamPlayer = $Hovered
@onready var _pressed_sfx : AudioStreamPlayer = $Pressed



func _exit_tree():
	# in case of quiting while paused
	get_tree().paused = false

# TODO: separate menu pausing (ESC) from gameplay pausing. otherwise scripts that uses gameplay pause like SAUL letters
#       will prevent player from pausing the game while also being unable to function when the player pauses the game first
func pause(show_pause_menu : bool = false):
	if get_tree().paused: return
	
	get_tree().paused = true
	if show_pause_menu:
		show()

func unpause():
	if get_tree().paused == false: return
	
	get_tree().paused = false
	hide()

func _on_resume_pressed():
	_pressed_sfx.play()
	unpause()

func _on_restart_pressed():
	# TODO: restart from checkpoint rather than this to not risk breaking levels that depend
	#       on a setup() func or previous context
	_pressed_sfx.play()
	SceneManager.restart_scene()

func _on_quit_pressed():
	_pressed_sfx.play()
	# main menu
	SceneManager.change_scene("res://Scenes/Game/main_menu.tscn")

func _on_mouse_entered():
	_hovered_sfx.play()
