@tool
extends ScrollContainer

signal pressed

@onready var _label : Label = $Label


func setup(text : String):
	_label.text = text

func _on_gui_input(event : InputEvent):
	if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
