extends PanelContainer

signal closed(is_yes_pressed : bool)

@onready var _main_text : RichTextLabel = $MarginContainer/VBoxContainer/RichTextLabel
@onready var _third_option_btn : Button = $MarginContainer/VBoxContainer/HBoxContainer/Third

var _third_option_text : Array[Dictionary] = [
	{
		"dialogue":"Here's a more in depth explanation: as long as the recorder is running and as long as the game window is open and focused every button, mouse or joypad input will be recorded. when the game is closed that recorded data will be saved into a file, which you can share on discord if you want to. using that data the developers (or anyone using the project) can read that saved input and replay it as if the original player was playing in from of them. The ultimate goal is to get better insights into how playtesting goes.",
		"button_txt":"That's what they want you to think",
	},
	{
		"dialogue":"What does that even.. you realize you're talking to the embodiment of a developer?",
		"button_txt":"What's that about my mom?"
	},
	{
		"dialogue":"Your what now? are you sure you're in the right place? How did you find this game?",
		"button_txt":"There's a kangaroo in my backyard"
	},
	{
		"dialogue":"You know what? enough of that we'll go back to Yes and No answers. are you okay with having the input recorder on?",
		"button_txt":""
	}
]
var _third_option_text_idx : int = 0


func _on_yes_pressed():
	closed.emit(true)

func _on_no_pressed():
	closed.emit(false)

func _on_third_pressed():
	var text_data : Dictionary = _third_option_text[_third_option_text_idx]
	_main_text.text = "[center]" + text_data["dialogue"] + "[/center]"
	if text_data["button_txt"].is_empty() == false:
		_third_option_btn.text = text_data["button_txt"]
	else:
		_third_option_btn.hide()
	
	_third_option_text_idx += 1
