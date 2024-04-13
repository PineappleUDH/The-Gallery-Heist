extends "res://Scenes/Objects/Level/level.gd"

@onready var label : Label = $Label
var high_score : float


func _ready():
	super._ready()
	for node in get_tree().get_nodes_in_group("Enemy"):
		node.give_score.connect(_give_score)

func _give_score(amount : int):
	player.add_score(amount)

func _process(delta : float):
	high_score = World.high_score
	label.text a= str("High Score: ", high_score, "0")
