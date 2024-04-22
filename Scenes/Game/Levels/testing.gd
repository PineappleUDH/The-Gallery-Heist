extends "res://Scenes/Objects/Level/level.gd"

@onready var _projectile_spawn_marker : Marker2D = $ProjectileSpawnPoint

const _projectile_scene : PackedScene = preload("res://Scenes/Objects/Projectiles/projectile_fire.tscn")

func _ready():
	super._ready()
	
	# temp while tesing projectiles
	while true:
		var projectile := _projectile_scene.instantiate()
		projectile.global_position = _projectile_spawn_marker.global_position
		add_child(projectile)
		projectile.setup(Vector2.RIGHT.rotated(TAU), randf_range(8, 14))
		await get_tree().create_timer(1).timeout
