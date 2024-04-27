extends CanvasLayer

signal scene_changed

@onready var _mouse_blocker : Control = $MouseBlocker
@onready var _black_fade : ColorRect = $BlackFade

const _tween_time : float = 0.9
var _is_transitioning : bool

func change_scene(scene_path : String, args : Dictionary = {}):
	if _is_transitioning: return
	_is_transitioning = true
	_mouse_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# fade in
	var tween : Tween = create_tween()
	tween.tween_property(_black_fade, "color:a", 1.0, _tween_time)
	await tween.finished
	
	# change scene. manual change is the only way to ensure that scene_changed emits right after the new scene is ready
	await get_tree().process_frame
	get_tree().current_scene.free()
	var new_scene : Node = load(scene_path).instantiate()
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	if args:
		assert(new_scene.has_method("setup"), "Attempting to pass arguments to a new scene that doesn't have a setup() function")
		new_scene.setup(args)
	scene_changed.emit()
	
	# fade out
	tween = create_tween()
	tween.tween_property(_black_fade, "color:a", 0.0, _tween_time)
	await tween.finished
	
	# cleanup
	_mouse_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false

func restart_scene():
	change_scene(get_tree().current_scene.scene_file_path)
