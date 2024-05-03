extends "res://Scenes/Objects/Level/level.gd"

# attach this script to all labyrinth levels. it handles moving data
# and moving back to the testing scene

@onready var _labyrinth_key : Collectable = $CollectableLabyrinthKey

var _completed_doors : Dictionary
var _door_name : String

func setup(args : Dictionary):
	_completed_doors = args["completed_doors"]
	_door_name = args["door_name"]

func _ready():
	super._ready()
	_labyrinth_key.key_collected.connect(_on_labyrinth_key_collected)

func _on_labyrinth_key_collected():
	for door_name : String in _completed_doors.keys():
		if door_name == _door_name:
			_completed_doors[door_name] = true
			SceneManager.change_scene(
				"res://Scenes/Game/Levels/testing.tscn",
				# pass back the data
				{"completed_doors":_completed_doors}
			)
			return
