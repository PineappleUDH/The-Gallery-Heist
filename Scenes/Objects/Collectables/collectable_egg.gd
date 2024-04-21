extends "res://Scenes/Objects/Collectables/collectable.gd"


func _ready():
	pass

func _collected(player : Player):
	World.level.add_score(5)
	#_collected_sfx.play()
	#_presistent_node.detach()
	queue_free()
