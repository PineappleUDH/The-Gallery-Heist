extends "res://Scenes/Objects/Collectables/collectable.gd"

@onready var _collected_sfx = $PersistentNodesContainer/Collected
@onready var _persistent_node = $PersistentNodesContainer

func _ready():
	pass

func _collected(player : Player):
	World.level.add_score(10)
	_collected_sfx.play()
	_persistent_node.detach()
	queue_free()
