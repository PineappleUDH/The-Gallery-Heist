extends Node

# global data for the game, if data is specific to a Level
# store it in Level class instead

var level : Level
var artwork_recoverd : Dictionary
var unlocked_levels : Array
var high_score : int

func _ready():
	SceneManager.scene_changed.connect(_on_scene_changed)
	_on_scene_changed() # call for starting scene

func _on_scene_changed():
	if get_tree().current_scene is Level:
		level = get_tree().current_scene
		level.score_changed.connect(_on_level_score_changed)
	else:
		level = null

func _on_level_score_changed():
	if level.get_score() > high_score:
		high_score = level.get_score()
