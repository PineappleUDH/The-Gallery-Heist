extends CanvasLayer

@onready var _health_container : HBoxContainer = $Hud/HBoxContainer/VBoxContainer/Health
@onready var _air_container : HBoxContainer = $Hud/HBoxContainer/VBoxContainer/Air
@onready var _dash_ui : TextureRect = $Hud/PlayerUiDash
@onready var _score_container : HBoxContainer = $Hud/HBoxContainer/Score
@onready var _score_tex : TextureRect = $Hud/HBoxContainer/Score/TextureRect
@onready var _score_label : Label = $Hud/HBoxContainer/Score/Label
@onready var _hide_coins_timer : Timer = $Hud/HideCoinsTimer

const _heart_ui_scene : PackedScene = preload("res://Scenes/Objects/Interface/player_ui_heart.tscn")
const _air_ui_scene : PackedScene = preload("res://Scenes/Objects/Interface/player_ui_air.tscn")

var _dash_locked : bool
const _hide_score_transparency : float = 0.5
var _score_tween : Tween
const _score_tween_time : float = 0.42


func _ready():
	_air_container.hide()
	_score_tex.pivot_offset = _score_tex.size / 2.0
	_score_container.modulate.a = _hide_score_transparency

func setup(max_health : int, max_air : int):
	# setup so changing the values in player class doesn't require manualy changing
	#       ui elements here, long live automation!
	
	# remove preview ui
	for child in _health_container.get_children(): child.queue_free()
	for child in _air_container.get_children(): child.queue_free()
	
	for i in max_health:
		var instance := _heart_ui_scene.instantiate()
		_health_container.add_child(instance)
	
	for i in max_air:
		var instance := _air_ui_scene.instantiate()
		_air_container.add_child(instance)

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

func set_dash(enabled : bool):
	if _dash_locked: return
	
	var animator : AnimationPlayer = _dash_ui.get_node("AnimationPlayer")
	if enabled:
		animator.play("fill")
	else:
		animator.play("used")

func set_dash_locked(locked : bool):
	_dash_locked = locked
	var animator : AnimationPlayer = _dash_ui.get_node("AnimationPlayer")
	if locked:
		animator.play("locked")
	else:
		animator.play("used_one_frame")

func set_score(score : int):
	_score_label.text = str(score)
	
	_score_container.modulate.a = 1.0
	_hide_coins_timer.start()
	
	if _score_tween && _score_tween.is_valid():
		_score_tween.kill()
	
	_score_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_score_tween.tween_property(_score_tex, "scale", Vector2.ONE, _score_tween_time)\
		.from(Vector2.ONE * 2.0)

func _on_hide_coins_timeout():
	_score_container.modulate.a = _hide_score_transparency
