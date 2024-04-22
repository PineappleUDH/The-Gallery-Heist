extends "res://Scenes/Objects/Collectables/collectable.gd"

const _amount_healed : int = 1

#@onready var _collected_sfx = $PersistentNodesContainer/Collected
#@onready var _persistent_node = $PersistentNodesContainer

func _ready():
	_bob_height = 3
	_bob_speed = 2
	_idle_movement = IdleMovement.sin_wave

func _collected(player : Player):
	player.heal(_amount_healed)
	#_collected_sfx.play()
	#_persistent_node.detach()
	queue_free()
