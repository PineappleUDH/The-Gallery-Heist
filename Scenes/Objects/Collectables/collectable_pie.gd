extends "res://Scenes/Objects/Collectables/collectable.gd"

@onready var _presistent_node : Node = $PersistentNodesContainer
@onready var _collected_sfx : AudioStreamPlayer = $PersistentNodesContainer/Collected
@onready var sprite_2d = $Sprite2D


func _ready():
	_idle_movement = IdleMovement.sin_wave
	sprite_2d.frame = randi_range(1,7)

func _collected(player : Player):
	World.level.add_score()
	_collected_sfx.play()
	_presistent_node.detach()
	queue_free()
