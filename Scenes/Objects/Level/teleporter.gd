extends Area2D
class_name Teleporter

@export var _target_teleporter : Teleporter

@onready var output_location : Node2D = $OutputLocation
@onready var _count_label : Label = $Count
@onready var _count_timer : Timer = $CountTimer

const _max_count_number : int = 3
var _count_number = _max_count_number


func _on_body_entered(body : Node2D):
	if body.is_in_group("Player"):
		_count_timer.start()
		
		_count_label.show()
		_count_number = _max_count_number
		_count_label.text = str(_count_number)

func _on_body_exited(body : Node2D):
	if body.is_in_group("Player"):
		_count_timer.stop()
		_count_label.hide()

func _on_count_timer_timeout():
	_count_number -= 1
	_count_label.text = str(_count_number)
	
	if _count_number == 0:
		# teleport
		_count_timer.stop()
		_count_label.hide()
		World.level.player.global_position = _target_teleporter.output_location.global_position
