extends CanvasLayer

@onready var _health_container : HBoxContainer = $MarginContainer/HBoxContainer/Health


func set_health(from : int, to : int):
	if from == to: return
	
	for i in _health_container.get_child_count():
		var heart_animator : AnimationPlayer = _health_container.get_child(i).get_node("AnimationPlayer")
		var i_adj : int = i+1 # adjusted i to account for health starting for 0
		
		if from < to && i_adj > from && i_adj <= to:
			# health added
			heart_animator.clear_queue()
			heart_animator.play("heal")
			heart_animator.queue("full")
		
		elif from > to && i_adj > to && i_adj <= from:
			# health removed
			heart_animator.clear_queue()
			heart_animator.play("damage")
			heart_animator.queue("empty")
