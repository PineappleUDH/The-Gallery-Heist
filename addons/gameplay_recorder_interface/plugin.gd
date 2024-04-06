@tool
extends EditorPlugin

const _interface_scene : PackedScene = preload("res://addons/gameplay_recorder_interface/gri_interface.tscn")
var _interface_instance : Control
var _is_interface_in_bottom_panel : bool

func _enter_tree():
	_interface_instance = _interface_scene.instantiate()
	
	scene_changed.connect(_on_scene_changed)
	_check_interface_visibility()

func _exit_tree():
	if _is_interface_in_bottom_panel:
		remove_control_from_bottom_panel(_interface_instance)

func _on_scene_changed(scene_root : Node):
	_check_interface_visibility()

func _check_interface_visibility():
	if get_editor_interface().get_edited_scene_root() is GameplayRecorder:
		# only show interface when GameplayRecorder scene is open to avoid crowding the editor
		add_control_to_bottom_panel(_interface_instance, "Gameplay Recorder Interface")
		_interface_instance.detect_files()
		_is_interface_in_bottom_panel = true
	else:
		remove_control_from_bottom_panel(_interface_instance)
		_is_interface_in_bottom_panel = false
