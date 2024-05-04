extends MarginContainer

@onready var _character_name_label : Label = $PanelContainer/VBoxContainer/Character
@onready var _text : RichTextLabel = $PanelContainer/VBoxContainer/RichTextLabel
@onready var _next_icon : TextureRect = $PanelContainer/NextIcon

const _char_time : float = 0.06
var _char_timer : float
var _sequence : Array[Dialogue]
var _curr_sequence_idx : int
var _is_dialogue_active : bool
var _is_dialogue_blocking : bool
var _is_building_text : bool
var _total_text_characters : int

# TODO: consider a short cooldown timer right after text is fully shown the ignores the next_dialogue input
#       so players don't accidentaly skip dialogue while trying to show all text

func _ready():
	set_process(false)

func _input(event : InputEvent):
	if event.is_action_pressed("next_dialogue") && _is_dialogue_active:
		if _is_building_text:
			# show all text
			_show_all_text()
		else:
			# next
			_next_dialogue_in_sequence()

func _process(delta : float):
	_char_timer -= delta
	if _char_timer <= 0.0:
		# show next char
		var chars_to_show : int = 1 + (abs(_char_timer) / _char_time)
		_text.visible_characters = min(
			_text.visible_characters + chars_to_show, _total_text_characters
		)
		
		if _text.visible_ratio == 1:
			# all text shown
			_show_all_text()
		else:
			var remainder : float = fmod(abs(_char_timer), _char_time)
			_char_timer = _char_time - remainder

func play_dialogue(dialogue_sequence : Array[Dialogue], is_blocking : bool):
	if _is_dialogue_active:
		if _is_dialogue_blocking && is_blocking == false:
			# non-blocking dialogue can't replace blocking dialogue since the latter is more important
			push_warning("Attempting to play non-blocking dialogue while a blocking dialogue is playing. blocking dialogue is considered more important and therefore this will be ignored")
			return
		else:
			# clear previous dialogue
			pass
	
	show()
	_is_dialogue_blocking = is_blocking
	if _is_dialogue_blocking: World.level.player.set_dummy_locks(true)
	_sequence = dialogue_sequence
	_is_dialogue_active = true
	_curr_sequence_idx = -1
	_next_dialogue_in_sequence()

func _next_dialogue_in_sequence():
	_curr_sequence_idx += 1
	if _curr_sequence_idx == _sequence.size():
		# dialogue sequence finished
		if _is_dialogue_blocking: World.level.player.set_dummy_locks(false)
		_is_dialogue_active = false
		_sequence.clear()
		_text.text = ""
		_total_text_characters = 0
		hide()
		return
	
	var _dialogue : Dialogue = _sequence[_curr_sequence_idx]
	
	_text.text = "[center]" + _dialogue.text + "[/center]"
	_total_text_characters = _text.get_total_character_count()
	_text.visible_characters = 0
	_character_name_label.text = _dialogue.character_name
	
	_dialogue.portrait # TODO
	
	set_process(true)
	_next_icon.hide()
	_is_building_text = true
	_char_timer = _char_time

func _show_all_text():
	_next_icon.show()
	_is_building_text = false
	_text.visible_ratio = 1
	set_process(false)
