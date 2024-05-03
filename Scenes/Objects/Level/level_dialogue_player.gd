extends MarginContainer

@onready var _character_name_label : Label = $PanelContainer/VBoxContainer/Character
@onready var _text : RichTextLabel = $PanelContainer/VBoxContainer/RichTextLabel
@onready var _next_icon : TextureRect = $PanelContainer/NextIcon

const _char_time : float = 0.2
var _char_timer : float
var _is_dialogue_active : bool
var _is_building_text : bool
var _total_text_characters : int
var _is_dialogue_blocking : bool

func _ready():
	set_process(false)

func _input(event : InputEvent):
	if event.is_action_pressed("next_dialogue") && _is_dialogue_active:
		if _is_building_text:
			# show all text
			pass
		else:
			# next
			pass

func _process(delta : float):
	_char_timer -= delta
	if _char_timer <= 0.0:
		# show next char
		var chars_to_show : int = 1 + (_char_timer / abs(_char_timer))
		_text.visible_characters = max(
			_text.visible_characters + chars_to_show, _total_text_characters
		)
		
		if _text.visible_ratio == 1:
			# all text shown
			_next_icon.show()
			_is_building_text = false
			set_process(false)
		else:
			var remainder : float = fmod(_char_timer, abs(_char_timer))
			_char_timer = _char_time - remainder

func play_dialogue(dialogue : Dialogue, is_blocking : bool):
	assert(dialogue.text, "Dialogue text can't be empty")
	
	if _is_dialogue_active:
		if _is_dialogue_blocking && is_blocking == false:
			# non-blocking dialogue can't replace blocking dialogue since the latter is more important
			pass
		else:
			# clear previous dialogue
			pass
	
	show()
	_total_text_characters = _text.get_total_character_count()
	_text.text = "[center]" + dialogue.text + "[/center]"
	_text.visible_characters = 0
	_character_name_label.text = dialogue.character_name
	_is_dialogue_blocking = is_blocking
	
	dialogue.portrait # TODO
	
	_next_icon.hide()
	_is_building_text = true
	_is_dialogue_active = true
	set_process(true)
	_char_timer = _char_time
