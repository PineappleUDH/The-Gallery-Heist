extends "res://Scenes/Objects/Collectables/collectable.gd"

@onready var _sprite = $Sprite

@export var _letter : Level.SaulLetter

func _ready():
	_sprite.play(Level.SaulLetter.keys()[_letter])

func _collected(player : Player):
	World.level.found_letter(_letter)
	# TODO: insert cool animation here, also sfx
	queue_free()
