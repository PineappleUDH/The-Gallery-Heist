extends "res://Scenes/Objects/Characters/Enemies/enemy.gd"

@onready var _sprite : Sprite2D = $Sprite
@onready var _gap_detect_left : RayCast2D = $Detectors/GapDetectLeft
@onready var _gap_detect_right : RayCast2D = $Detectors/GapDetectRight
@onready var _debug_vars_visualizer : PanelContainer = $DebugVarsVisualizer

var _state_machine : StateMachine = StateMachine.new()
const _wander_speed : float = 50.0

func _ready():
	_max_health = 2
	_damage_cooldown_time = 1.0
	_health = _max_health
	_knockback = 130.0
	
	_gap_detect_left.add_exception(self)
	_gap_detect_right.add_exception(self)
	
	_debug_vars_visualizer.add_var("State")
	
	_state_machine.add_state("wander", Callable(), Callable(), Callable(), _state_wander_ph_process)
	_state_machine.change_state("wander")
	
func _process(delta : float):
	super._process(delta)
	_state_machine.state_process(delta)
	
	_debug_vars_visualizer.edit_var("State", _state_machine.get_current_state())
	
	if _direction.x == 1:
		_sprite.flip_h = false
	elif _direction.x == -1:
		_sprite.flip_h = true

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)

func take_damage(damage : int, from : Vector2, is_deadly : bool = false) -> bool:
	return super.take_damage(damage, from, is_deadly)

func _state_wander_ph_process(delta: float):
	if not is_on_floor():
		velocity.y += _gravity * delta
	
	velocity.x = _direction.x * _wander_speed
	
	if is_on_floor():
		var velocity_sign : int = sign(velocity.x)
		# TODO: we flip direction when a fall is detected but not when a wall is detected
		if ((velocity_sign == 1 && _gap_detect_right.is_colliding() == false) ||
		(velocity_sign == -1 && _gap_detect_left.is_colliding() == false)):
			_direction.x = -_direction.x
	
	move_and_slide()
