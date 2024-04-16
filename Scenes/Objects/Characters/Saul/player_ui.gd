extends CanvasLayer

@onready var _health_container : HBoxContainer = $MarginContainer/HBoxContainer/VBoxContainer/Health
@onready var _air_container : HBoxContainer = $MarginContainer/HBoxContainer/VBoxContainer/Air


func setup(max_health : int, max_air : int):
	# TODO: implement so changing the values in player class doesn't require manualy changing
	#       ui elements here, long live automation!
	pass

func set_health(from : int, to : int):
	if from == to: return
	
	for i in _health_container.get_child_count():
		var heart_animator : AnimationPlayer = _health_container.get_child(i).get_node("AnimationPlayer")
		var i_adj : int = i+1 # adjusted i to account for health starting for 0
		
		if from < to && i_adj > from && i_adj <= to:
			# health added
			heart_animator.clear_queue()
			heart_animator.play("heal")
			heart_animator.queue("idle")
		
		elif from > to && i_adj > to && i_adj <= from:
			# health removed
			heart_animator.clear_queue()
			heart_animator.play("damage")
			heart_animator.queue("empty")

func set_air(from : int, to : int):
	if from == to: return
	
	for i in _air_container.get_child_count():
		var air_animator : AnimationPlayer = _air_container.get_child(i).get_node("AnimationPlayer")
		var i_adj : int = i+1
		
		if from < to && i_adj > from && i_adj <= to:
			# air added
			air_animator.clear_queue()
			air_animator.play("restore")
			air_animator.queue("idle")
		
		elif from > to && i_adj > to && i_adj <= from:
			# air removed
			air_animator.clear_queue()
			air_animator.play("pop")

func set_air_active(active : bool):
	_air_container.visible = active
