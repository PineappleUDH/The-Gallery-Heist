extends PanelContainer

@onready var _label : Label = $MarginContainer/VBoxContainer/Label
@onready var _btn1 : Button = $MarginContainer/VBoxContainer/Primary
@onready var _btn2 : Button = $MarginContainer/VBoxContainer/Secondary

var _bind1 : InputEventWithModifiers
var _bind2 : InputEventWithModifiers
var _focused_bind : int = 0 # 1 for bind1, 2 for bind2
const _exit_key : int = KEY_DELETE
const _undefined_bind : String = "<underfined>"

func setup(action_name : String, bind1 : InputEventWithModifiers, bind2 : InputEventWithModifiers):
	for bind in [bind1, bind2]:
		# only keyboard and mouse buttons are supported
		assert(bind == null || bind is InputEventKey || bind is InputEventMouseButton)
	_clean_input(bind1)
	_clean_input(bind2)
	
	_label.text = action_name
	_bind1 = bind1
	_bind2 = bind2
	_btn1.text = bind1.as_text() if bind1 else _undefined_bind
	_btn2.text = bind2.as_text() if bind2 else _undefined_bind

func _input(event : InputEvent):
	if _focused_bind == 0 || (event is InputEventKey == false && event is InputEventMouseButton == false): return
	
	var bind_changed : bool = false
	if event is InputEventKey && event.pressed && event.keycode == _exit_key:
		# exit
		if _focused_bind == 1:
			_bind1 = null
			_btn1.text = _undefined_bind
		elif _focused_bind == 2:
			_bind2 = null
			_btn2.text = _undefined_bind
		bind_changed = true
	
	elif event.is_pressed():
		_clean_input(event)
		
		if _focused_bind == 1:
			_bind1 = event
			_btn1.text = event.as_text()
		elif _focused_bind == 2:
			_bind2 = event
			_btn2.text = event.as_text()
		bind_changed = true
	
	if bind_changed:
		_focused_bind = 0
		get_viewport().gui_release_focus()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func get_data() -> Dictionary:
	return {"name":_label.text, "bind1":_bind1, "bind2":_bind2}

func _clean_input(event : InputEventWithModifiers):
	if event:
		# if player holds a modifier while setting keys ignore it, we don't support multiple keys at once
		event.alt_pressed = false
		event.ctrl_pressed = false
		event.meta_pressed = false
		event.shift_pressed = false
		
		if event is InputEventKey:
			# _input() key events come with keycode, physical_keycode and unicode all set
			# while InputMap key events only have 1 of the 3. we want our keybinds to be physical keys
			# so it's the same button no matter what keyboard layout is used
			event.keycode = KEY_NONE
			event.unicode = KEY_NONE

func _on_focus_entered(is_first : bool):
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if is_first: _focused_bind = 1
	else: _focused_bind = 2
