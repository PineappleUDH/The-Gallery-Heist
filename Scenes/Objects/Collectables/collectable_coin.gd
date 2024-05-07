extends "res://Scenes/Objects/Collectables/collectable.gd"

@onready var _presistent_node : Node = $PersistentNodesContainer
@onready var _collected_sfx : AudioStreamPlayer = $PersistentNodesContainer/Collected


func _ready():
	_idle_movement = IdleMovement.sin_wave

func _collected(player : Player):
	World.level.add_score()
	_collected_sfx.play()
	_presistent_node.detach()
	super._collected(player)
