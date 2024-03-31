extends CanvasLayer

signal scene_changed

enum _TransitionDirection {left_to_right, right_to_left, up_to_down, down_to_up, scaled}

@onready var _transition_tex : TextureRect = $ScreenTransition
@onready var _mouse_blocker : Control = $MouseBlocker

const _transitions : Array[Dictionary] = [
	{"texture":"res://Resources/Textures/SceneTrainsitions/ArrowHorizontal.png", "transition":_TransitionDirection.left_to_right},
	{"texture":"res://Resources/Textures/SceneTrainsitions/ArrowVertical.png", "transition":_TransitionDirection.down_to_up},
	{"texture":"res://Resources/Textures/SceneTrainsitions/Rectangle.png", "transition":_TransitionDirection.scaled},
]
const _transition_positions : Dictionary = {
	# based on edges of TransitionTemplate.png
	"center":Vector2(160,20), "left":Vector2(-800,20), "right":Vector2(1120,20), "up":Vector2(160,-800), "down":Vector2(160,840)
}
var _is_transitioning : bool
const _tween_time : float = 0.5
const _transition_tex_scale : Vector2 = Vector2.ONE * 4.0


func change_scene(scene_path : String):
	if _is_transitioning: return
	_is_transitioning = true
	
	# setup
	_mouse_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	var random_trans : Dictionary = _transitions.pick_random()
	_transition_tex.texture = load(random_trans["texture"])
	
	# cover screen
	var tween : Tween = create_tween()
	match random_trans["transition"]:
		_TransitionDirection.left_to_right:
			tween.tween_property(_transition_tex, "position", _transition_positions["center"], _tween_time)\
				.from(_transition_positions["left"])
		_TransitionDirection.right_to_left:
			tween.tween_property(_transition_tex, "position", _transition_positions["center"], _tween_time)\
				.from(_transition_positions["right"])
		_TransitionDirection.up_to_down:
			tween.tween_property(_transition_tex, "position", _transition_positions["center"], _tween_time)\
				.from(_transition_positions["up"])
		_TransitionDirection.down_to_up:
			tween.tween_property(_transition_tex, "position", _transition_positions["center"], _tween_time)\
				.from(_transition_positions["down"])
		_TransitionDirection.scaled:
			tween.tween_property(_transition_tex, "scale", _transition_tex_scale, _tween_time)\
				.from(Vector2.ZERO)
	await tween.finished
	
	# change scene
	await get_tree().process_frame
	get_tree().change_scene_to_file(scene_path)
	get_tree().process_frame.connect(
		# there is no emit_deferred, so we do it manually
		func(): scene_changed.emit(),
		CONNECT_ONE_SHOT
	)
	
	# uncover screen
	tween = create_tween()
	match random_trans["transition"]:
		_TransitionDirection.left_to_right:
			tween.tween_property(_transition_tex, "position", _transition_positions["right"], _tween_time)
		_TransitionDirection.right_to_left:
			tween.tween_property(_transition_tex, "position", _transition_positions["left"], _tween_time)
		_TransitionDirection.up_to_down:
			tween.tween_property(_transition_tex, "position", _transition_positions["down"], _tween_time)
		_TransitionDirection.down_to_up:
			tween.tween_property(_transition_tex, "position", _transition_positions["up"], _tween_time)
		_TransitionDirection.scaled:
			tween.tween_property(_transition_tex, "scale", Vector2.ZERO, _tween_time)
	await tween.finished
	
	# cleanup
	_transition_tex.texture = null
	_transition_tex.position = _transition_positions["center"]
	_transition_tex.scale = _transition_tex_scale
	_mouse_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false

func restart_scene():
	change_scene(get_tree().current_scene.scene_file_path)
