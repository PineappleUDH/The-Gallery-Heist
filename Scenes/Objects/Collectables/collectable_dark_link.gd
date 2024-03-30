extends "res://Scenes/Objects/Collectables/collectable.gd"

@onready var _text : Label = $Darklinktext/text
@onready var _scrambletimer : Timer = $Darklinktext/scrambletimer
const _characters : String = 'abd#&,[/eh_ijlmpqtu?vwxz*~`'
var _txt1 : String = "eiw"
var _txt2 : String = "s?f"
var _lastupdate1 : bool = false
var _txtdic : Dictionary = {"txt1":_txt1, "txt2":_txt2}

func _ready():
	_idle_movement = IdleMovement.sin_wave
	
	var textscramble : String = generate_word(_characters, 6)
	_text.text = "http://" + textscramble

func generate_word(chars : String, length : int) -> String:
	var word : String
	var n_char : int = len(chars)
	for i in range(length):
		word += chars[randi() % n_char]
	return word

func _collected(player : Player):
	super._collected(player)

func _updatetext(txt : String):
	if _lastupdate1 == false:
		_txt1 = txt
		_lastupdate1 = true
	elif _lastupdate1 == true:
		_txt2 = txt
		_lastupdate1 = false
	_text.text = _txtdic["txt1"] + _txtdic["txt2"]

func _on_scrambletimer_timeout():
	var textscramble : String = generate_word(_characters, 3)
	_updatetext(textscramble)
	_scrambletimer.start()
