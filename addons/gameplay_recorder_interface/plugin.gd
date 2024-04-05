@tool
extends EditorPlugin

const _interface_scene : PackedScene = preload("res://addons/gameplay_recorder_interface/gri_interface.tscn")
var _interface_instance : Control

func _enter_tree():
	_interface_instance = _interface_scene.instantiate()
	add_control_to_bottom_panel(_interface_instance, "Gameplay Recorder Interface")

func _exit_tree():
	remove_control_from_bottom_panel(_interface_instance)

func _apply_changes():
	_interface_instance.apply_changed()
