extends "res://Scenes/Objects/Level/level.gd"

@onready var _projectile_spawn_marker : Marker2D = $ProjectileSpawnPoint
@onready var _labyrinth_doors_container : Node2D = $Labyrinth/Doors
@onready var _labyrinth_status_label : Label = $Labyrinth/Status/Label
@onready var _labyrinth_lock : StaticBody2D = $Labyrinth/LabyrinthLock
@onready var _labyrinth_lock_label : Label = $Labyrinth/LabyrinthLock/Label
@onready var _labyrinth_spawn_point : Marker2D = $Labyrinth/SpawnPoint

const _projectile_scene : PackedScene = preload("res://Scenes/Objects/Projectiles/projectile_fire.tscn")

const _labyrinth_states_time : float = 3.5
var _completed_labyrinth_doors : Dictionary # {door_name:is_open, ...}

func setup(args : Dictionary):
	# setup is called by labyrinth levels to pass their updated labyrinth doors data
	# the new data has the door player came back from set to true
	var all_doors : int = _completed_labyrinth_doors.keys().size()
	var unlocked_doors : int = 0
	_completed_labyrinth_doors = args["completed_doors"]
	for door_name : String in _completed_labyrinth_doors.keys():
		if _completed_labyrinth_doors[door_name]:
			_labyrinth_doors_container.get_node(door_name).set_finished(true)
			unlocked_doors += 1
	
	player.global_position = _labyrinth_spawn_point.global_position
	_player_starting_position = _labyrinth_spawn_point.global_position
	
	# display text
	_labyrinth_status_label.show()
	if unlocked_doors == _completed_labyrinth_doors.keys().size() - 1:
		_labyrinth_status_label.text = "All levels finished!"
	else:
		_labyrinth_status_label.text = "%d out of %d finished!" % [unlocked_doors, all_doors]
	
	# lock
	if unlocked_doors == _completed_labyrinth_doors.keys().size() - 1:
		# all levels completed, yaaay!
		_labyrinth_lock.queue_free()
	else:
		_labyrinth_lock_label.text = "%d doors left" % [all_doors - unlocked_doors]
	
	await get_tree().create_timer(_labyrinth_states_time).timeout
	_labyrinth_status_label.hide()

func _ready():
	super._ready()
	
	for door in _labyrinth_doors_container.get_children():
		_completed_labyrinth_doors[door.name] = false
		door.level_entered.connect(_on_door_level_entered.bind(door.name))
	
	# temp while tesing projectiles
	while true:
		var projectile := _projectile_scene.instantiate()
		projectile.global_position = _projectile_spawn_marker.global_position
		add_child(projectile)
		projectile.setup(Vector2.RIGHT.rotated(TAU), randf_range(8, 14))
		await get_tree().create_timer(1).timeout

func _on_door_level_entered(scene : String, door_name : String):
	var args : Dictionary = {"completed_doors":_completed_labyrinth_doors, "door_name":door_name}
	SceneManager.change_scene(scene, args)
