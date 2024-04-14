extends "res://Scenes/Objects/Collectables/collectable.gd"

@onready var _sprite = $Sprite

@export var _letter : String = ""

#TODO add system for keeping track which letters in level are collected
func _ready():
	_sprite.play(_letter)
