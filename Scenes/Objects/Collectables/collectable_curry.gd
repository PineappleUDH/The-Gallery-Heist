extends "res://Scenes/Objects/Collectables/collectable.gd"

@onready var _collider : CollisionShape2D = $CollisionShape2D

const _amount_healed : int = 1

func _ready():
	_sin_height = 3
	_sin_speed = 2
	_idle_movement = IdleMovement.sin_wave
	
	await get_tree().process_frame
	World.level.player.respawned.connect(_on_player_respawned)

func _collected(player : Player):
	player.heal(_amount_healed)
	collected.emit()
	# sfx..
	
	# hide curry but don't delete it. when player dies and respawns
	# healing items should respawn too
	_collider.set_deferred("disabled", true)
	hide()

func _on_player_respawned():
	_collider.disabled = false
	show()
