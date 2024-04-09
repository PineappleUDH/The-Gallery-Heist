extends Control

@onready var _backgroud : ColorRect = $Background
@onready var _title_label : Label = $Label

var _flash_tween : Tween
const _flash_tween_time : float = 0.5
const _tween_rotation_range : float = deg_to_rad(20.0)


func _input(event : InputEvent):
	if event.is_action_pressed("skip"):
		SceneManager.change_scene("res://Scenes/Game/main_menu.tscn")

func _color_flash():
	if _flash_tween && _flash_tween.is_valid():
		_flash_tween.kill()
	
	_flash_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	_flash_tween.tween_property(
		_backgroud, "color", Color.BLACK, _flash_tween_time
	).from(Color.WHITE)
	_flash_tween.tween_property(
		_title_label, "theme_override_colors/font_color", Color.WHITE, _flash_tween_time
	).from(Color.BLACK)
	
	_flash_tween.tween_property(
		_title_label, "rotation",
		randf_range(-_tween_rotation_range, _tween_rotation_range),
		_flash_tween_time
	)
	_flash_tween.tween_property(
		_title_label, "scale",
		Vector2.ONE,
		_flash_tween_time
	).from(Vector2.ONE * 2)

func _reset():
	_title_label.rotation = 0.0

func _on_animation_finished(anim_name : StringName):
	SceneManager.change_scene("res://Scenes/Game/main_menu.tscn")
