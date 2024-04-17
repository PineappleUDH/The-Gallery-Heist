@tool
extends Node2D

enum _Pattern {grid, arc}

@export var _collectable : PackedScene :
	set(value):
		if value:
			# only way to check for PackedScene type is this :(
			var test_instance := value.instantiate()
			if test_instance is Collectable:
				_collectable = value
				_setup_stack()
			
			test_instance.free()
		else:
			_collectable = value
			_setup_stack()
@export var _pattern : _Pattern = _Pattern.grid :
	set(value):
		_pattern = value
		notify_property_list_changed()
		_setup_stack()

@export_group("Grid")
@export var _horizontal_count : int = 1 :
	set(value):
		_horizontal_count = max(value, 1)
		_setup_stack()
@export var _vertical_count : int = 1 :
	set(value):
		_vertical_count = max(value, 1)
		_setup_stack()
@export var _spacing : int = 24 :
	set(value):
		_spacing = max(value, 0)
		_setup_stack()

@export_group("Arc")
@export var _end_point : Vector2 :
	set(value):
		_end_point = value
		_setup_stack()
@export var _curve_bump : float :
	set(value):
		_curve_bump = value
		_setup_stack()
@export var _coins_count : int = 1 :
	set(value):
		_coins_count = max(value, 1)
		_setup_stack()

@onready var _stack_container : Node2D = $Stack


func _setup_stack():
	if is_node_ready() == false:
		await ready
	
	for child in _stack_container.get_children():
		child.queue_free()
	
	if _collectable == null: return
	
	match _pattern:
		_Pattern.grid:
			for i in _horizontal_count:
				for j in _vertical_count:
					var instance : Collectable = _collectable.instantiate()
					instance.global_position = Vector2(i * _spacing, j * _spacing)
					_stack_container.add_child(instance)
		
		_Pattern.arc:
			# bezier curve (I totally didn't spend an hour tearing my hair out until something happened)
			var p1 : Vector2 = Vector2.ZERO
			var p3 : Vector2 = _end_point
			var p2 : Vector2 = (_end_point / 2) + (p3 - p1).normalized().rotated(-PI/2) * _curve_bump
			
			for i in _coins_count:
				var t : float = remap(i, 0, _coins_count-1, 0.0, 1.0)
				var c1 : Vector2 = p1.lerp(p2, t)
				var c2 : Vector2 = p2.lerp(p3, t)
				var final : Vector2 = c1.lerp(c2, t)
				
				var instance : Collectable = _collectable.instantiate()
				instance.position = final
				_stack_container.add_child(instance)

func _validate_property(property: Dictionary):
	match property["name"]:
		"_horizontal_count", "_vertical_count", "_spacing":
			if _pattern != _Pattern.grid:
				property["usage"] = PROPERTY_USAGE_NO_EDITOR
		
		"_end_point", "_curve_bump", "_coins_count":
			if _pattern != _Pattern.arc:
				property["usage"] = PROPERTY_USAGE_NO_EDITOR
