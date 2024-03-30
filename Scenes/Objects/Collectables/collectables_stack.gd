@tool
extends Node2D

@export var _collectable : PackedScene :
	set(value):
		if value:
			var test_instance := value.instantiate()
			if test_instance is Collectable:
				_collectable = value
				_setup_stack()
			
			test_instance.free()
		else:
			_collectable = value
			_setup_stack()
@export var _horizontal_count : int = 0 :
	set(value):
		_horizontal_count = max(value, 0)
		_setup_stack()
@export var _vertical_count : int = 0 :
	set(value):
		_vertical_count = max(value, 0)
		_setup_stack()
@export var _spacing : int = 24 :
	set(value):
		_spacing = max(value, 0)
		_setup_stack()

@onready var _stack_container : Node2D = $Stack


func _setup_stack():
	if is_node_ready() == false:
		await ready
	
	for child in _stack_container.get_children():
		child.queue_free()
	
	if (_collectable == null ||
	_horizontal_count == 0 || _vertical_count == 0):
		return
	
	for i in _horizontal_count:
		for j in _vertical_count:
			var instance : Collectable = _collectable.instantiate()
			instance.global_position = Vector2(i * _spacing, j * _spacing)
			_stack_container.add_child(instance)
