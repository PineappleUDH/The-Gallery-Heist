@tool
extends Node2D

enum _Pattern {grid, arc, zigzag}

## a collectable object to use in the pattern, drag and drop from the Instances tab
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
## the pattern to use
@export var _pattern : _Pattern = _Pattern.grid :
	set(value):
		_pattern = value
		notify_property_list_changed()
		_setup_stack()

# TODO: rename grid and arc variables to start with "grid_.." or "arc.." so they don't clash with other vars
@export_group("Grid")
## horizontal grid count
@export var _horizontal_count : int = 1 :
	set(value):
		_horizontal_count = max(value, 1)
		_setup_stack()
## vertical grid count
@export var _vertical_count : int = 1 :
	set(value):
		_vertical_count = max(value, 1)
		_setup_stack()
## the spacing between collectables both horizontally (x) and vertically (y)
@export var _spacing : Vector2i = Vector2i(24, 24):
	set(value):
		_spacing.x = max(value.x, 0)
		_spacing.y = max(value.y, 0)
		_setup_stack()

@export_group("Arc")
## a position relative to this node's position where the last collectible will be placed
@export var _end_point : Vector2 :
	set(value):
		_end_point = value
		_setup_stack()
## how high the curve bump goes, 0 is a straight line the higher the value the more circle-like it will look
@export var _curve_bump : float :
	set(value):
		_curve_bump = value
		_setup_stack()
## number of collectables in the arc
@export var _arc_count : int = 1 :
	set(value):
		_arc_count = max(value, 1)
		_setup_stack()

@onready var _stack_container : Node2D = $Stack

@export_group("Zigzag")
## if true collectables will be placed vertically, if not they will be placed horizontally
@export var _zigzag_vertical : bool = true :
	set(value):
		_zigzag_vertical = value
		_setup_stack()
## the distance between collectables along the expansion direction (down for vertical, right for horizontal)
@export var _zigzag_height : float :
	set(value):
		_zigzag_height = value
		_setup_stack()
## the distance between collectables perpendicular to the expansion direction (right for vertical, down for horizontal)
@export var _zigzag_width : float :
	set(value):
		_zigzag_width = value
		_setup_stack()
## the number of points in the zigzag, each point could have 1 or more collectibles
@export var _zigzag_points : int :
	set(value):
		_zigzag_points = max(value, 2)
		_setup_stack()
## the number of collectables per point
@export var _zigzag_object_per_point : int :
	set(value):
		_zigzag_object_per_point = max(value, 1)
		_setup_stack()
## the spacing between collectables that belong to the same point
@export var _zigzag_object_spacing : float :
	set(value):
		_zigzag_object_spacing = value
		_setup_stack()


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
					instance.global_position = Vector2(i * _spacing.x, j * _spacing.y)
					_stack_container.add_child(instance)
		
		_Pattern.arc:
			# bezier curve (I totally didn't spend an hour tearing my hair out until something happened)
			var p1 : Vector2 = Vector2.ZERO
			var p3 : Vector2 = _end_point
			var p2 : Vector2 = (_end_point / 2) + (p3 - p1).normalized().rotated(-PI/2) * _curve_bump
			
			for i in _arc_count:
				var t : float = remap(i, 0, _arc_count-1, 0.0, 1.0)
				var c1 : Vector2 = p1.lerp(p2, t)
				var c2 : Vector2 = p2.lerp(p3, t)
				var final : Vector2 = c1.lerp(c2, t)
				
				var instance : Collectable = _collectable.instantiate()
				instance.position = final
				_stack_container.add_child(instance)
		
		_Pattern.zigzag:
			for p in _zigzag_points:
				var is_even : bool = p % 2 == 0
				
				var point_center : Vector2
				var point_ctbl_spacing : Vector2
				if _zigzag_vertical:
					point_center = Vector2(
						0.0 if is_even else _zigzag_width,
						p * _zigzag_height
					)
					point_ctbl_spacing = Vector2(0.0, _zigzag_object_spacing)
				else:
					point_center = Vector2(
						p * _zigzag_height,
						0.0 if is_even else _zigzag_width
					)
					point_ctbl_spacing = Vector2(_zigzag_object_spacing, 0.0)
				
				for c in _zigzag_object_per_point:
					var instance : Collectable = _collectable.instantiate()
					instance.position = (point_center + point_ctbl_spacing * (_zigzag_object_per_point - 1)) - point_ctbl_spacing * c
				
					_stack_container.add_child(instance)
			

func _validate_property(property: Dictionary):
	match property["name"]:
		"_horizontal_count", "_vertical_count", "_spacing":
			if _pattern != _Pattern.grid:
				property["usage"] = PROPERTY_USAGE_NO_EDITOR
		
		"_end_point", "_curve_bump", "_arc_count":
			if _pattern != _Pattern.arc:
				property["usage"] = PROPERTY_USAGE_NO_EDITOR
		
		"_zigzag_vertical", "_zigzag_height", "_zigzag_width", "_zigzag_points", "_zigzag_object_per_point", "_zigzag_object_spacing":
			if _pattern != _Pattern.zigzag:
				property["usage"] = PROPERTY_USAGE_NO_EDITOR
