extends "res://Scenes/Objects/Collectables/collectable.gd"

@onready var _sprite = $Sprite
@onready var _collected_sfx = $PersistentNodesContainer/Collected
@onready var _persistent_node = $PersistentNodesContainer

@export var _letter : Level.SaulLetter

func _ready():
	_sprite.play(Level.SaulLetter.keys()[_letter])

func _collected(player : Player):
	World.level.found_letter(_letter)
	_collected_sfx.play()
	_persistent_node.detach()
	# TODO: insert cool animation here
	queue_free()
