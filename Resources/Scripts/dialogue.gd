class_name Dialogue
extends Resource

@export var character_name : String = ""
@export_multiline var text : String
@export var portrait : Texture2D = null

static func create(text_ : String, character_name_ : String = "", portrait_ : Texture2D = null) -> Dialogue:
	# for one line setup in code when trying to create a dialogue array
	var dialogue : Dialogue = Dialogue.new()
	dialogue.text = text_
	dialogue.character_name = character_name_
	dialogue.portrait = portrait_
	if portrait_ != null: push_warning("Portraits are not supported yet")
	return dialogue
