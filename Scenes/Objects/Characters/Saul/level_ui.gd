extends CanvasLayer

@onready var _health_container : HBoxContainer = $Hud/HBoxContainer/Health
@onready var _air_container : HBoxContainer = $Hud/MarginContainer/Air
@onready var _dash_ui : TextureRect = $Hud/PlayerUiDash
@onready var _score_tex : TextureRect = $Hud/HBoxContainer/Score/TextureRect
@onready var _score_label : Label = $Hud/HBoxContainer/Score/Label

@onready var _letters_container : HBoxContainer = $Hud/Letters

const _heart_ui_scene : PackedScene = preload("res://Scenes/Objects/Interface/player_ui_heart.tscn")
const _air_ui_scene : PackedScene = preload("res://Scenes/Objects/Interface/player_ui_air.tscn")

var _dash_locked : bool
var _score_tween : Tween
const _score_tween_time : float = 0.42

var _show_letter_tween : Tween
const _show_letter_tween_time : float = 0.6


func _ready():
	_air_container.hide()
	_score_tex.pivot_offset = _score_tex.size / 2.0

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

func get_letters_ui_position() -> Vector2:
	return _letters_container.global_position + _letters_container.size / 2.0

func show_letters_found(found_letters : Dictionary):
	# TODO: better animation and special animation for finding all letters
	if _show_letter_tween && _show_letter_tween.is_valid():
		_show_letter_tween.kill()
	
	var found_letters_nodes : Array[TextureRect] = []
	for i in _letters_container.get_child_count():
		if found_letters[i]:
			found_letters_nodes.append(_letters_container.get_child(i))
			_letters_container.get_child(i).texture.region.position.x = 16
		else:
			# empty letter sprite
			_letters_container.get_child(i).texture.region.position.x = 64
	
	_letters_container.show()
	_show_letter_tween = create_tween().set_parallel(true)
	for letter_tex : TextureRect in found_letters_nodes:
		_show_letter_tween.tween_property(letter_tex, "modulate", Color.WHITE, _show_letter_tween_time)\
			.from(Color.ORANGE)
	
	_show_letter_tween.set_parallel(false)
	_show_letter_tween.tween_interval(_show_letter_tween_time)
	
	await _show_letter_tween.finished
	_letters_container.hide()

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
	animator.clear_queue()
	if enabled:
		animator.play("fill")
		animator.queue("idle")
	else:
		animator.play("used")

func set_dash_locked(locked : bool):
	if _dash_locked == locked: return
	
	_dash_locked = locked
	var animator : AnimationPlayer = _dash_ui.get_node("AnimationPlayer")
	animator.clear_queue()
	if locked:
		animator.play("locked")
	else:
		animator.play("used_one_frame")

func set_score(score : int):
	_score_label.text = str(score)
	
	if _score_tween && _score_tween.is_valid():
		_score_tween.kill()
	
	_score_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_score_tween.tween_property(_score_tex, "scale", Vector2.ONE, _score_tween_time)\
		.from(Vector2.ONE * 2.0)
