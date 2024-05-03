extends MarginContainer

@onready var _text : RichTextLabel = $PanelContainer/RichTextLabel

var _curr_dialogue : Dialogue

func play_dialogue(dialogue : Dialogue):
	_text.text = "[center]" + dialogue.text + "[/center]"
	
	dialogue.is_blocking
	dialogue.character_name
	dialogue.portrait
