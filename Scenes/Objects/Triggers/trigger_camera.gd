@tool
class_name TriggerCamera
extends "res://Scenes/Objects/Triggers/trigger.gd"

@export var _change_state : bool = false :
	set(value):
		_change_state = value
		queue_redraw()
		notify_property_list_changed()
@export var _change_zoom : bool = false :
	set(value):
		_change_zoom = value
		notify_property_list_changed()
@export var _change_lock : bool = false :
	set(value):
		_change_lock = value
		notify_property_list_changed()

@export_group("Camera State")
@export var _trigger_state : LevelCamera.CameraState :
	set(value):
		_trigger_state = value
		queue_redraw()
		notify_property_list_changed()
@export var _idle_position : Vector2 :
	set(value):
		_idle_position = value
		queue_redraw()

@export_group("Axis Lock")
@export var _release_x_bound : bool = true :
	set(value):
		_release_x_bound = value
		notify_property_list_changed()
@export var _release_y_bound : bool = true :
	set(value):
		_release_y_bound = value
		notify_property_list_changed()
@export var _x_bound : Vector2
@export var _y_bound : Vector2

@export_group("Camera Properties")
@export var _zoom : Vector2 = Vector2.ONE :
	set(value):
		_zoom = value
		queue_redraw()

const _preview_color : Color = Color("ffffff64")


func _draw():
	if Engine.is_editor_hint() == false: return
	
	if _change_state && _trigger_state == LevelCamera.CameraState.idle:
		# draw idle position preview
		var local_idle_pos : Vector2 = _idle_position - position
		draw_line(Vector2.ZERO, local_idle_pos, _preview_color)
		draw_circle(local_idle_pos, 2, _preview_color)
		
		var half_viewport_size : Vector2 =\
			Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))\
			/ 2.0 / _zoom
		draw_rect(
			Rect2(local_idle_pos - half_viewport_size, (local_idle_pos + half_viewport_size) - (local_idle_pos - half_viewport_size)),
			_preview_color, false
		)

# TODO: if player enters trigger A and then enters trigger B while
#       also partly inside trigger A, B will apply but if the player
#       immediately goes back to the direction of trigger A, A won't
#       apply back because _player_entered will not be called since the player
#       never left trigger A. with me so far? this can happen if the distance
#       between A and B is smaller than player collider size.
func apply_camera_state():
	var camera : LevelCamera = World.level.level_camera
	
	if _change_state == false && _change_zoom == false && _change_lock == false:
		push_warning("Camera trigger has no effect")
		return
	
	if _change_state:
		match _trigger_state:
			LevelCamera.CameraState.idle:
				camera.set_state_idle(_idle_position)
			LevelCamera.CameraState.follow:
				camera.set_state_follow()
	
	if _change_zoom:
		camera.set_target_zoom(_zoom)
	
	if _change_lock:
		if _release_x_bound == true:
			camera.remove_axis_bound(true)
		elif _release_x_bound == false:
			camera.set_axis_bound(true, _x_bound)
		
		if _release_y_bound == true:
			camera.remove_axis_bound(false)
		elif _release_y_bound == false:
			camera.set_axis_bound(false, _y_bound)

func _player_entered():
	apply_camera_state()

func _validate_property(property : Dictionary):
	var hide_prop : Callable = func():
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
	
	# hide properties that aren't used
	match property["name"]:
		"_trigger_state", "_idle_position":
			if _change_state == false:
				hide_prop.call()
			
			if property["name"] == "_idle_position":
				if _trigger_state != LevelCamera.CameraState.idle:
					hide_prop.call()
		
		"_zoom":
			if _change_zoom == false:
				hide_prop.call()
		
		"_x_bound", "_y_bound", "_release_x_bound", "_release_y_bound":
			if _change_lock == false:
				hide_prop.call()
		
			else:
				if property["name"] == "_x_bound":
					if _release_x_bound:
						hide_prop.call()
				
				elif property["name"] == "_y_bound":
					if _release_y_bound:
						hide_prop.call()
