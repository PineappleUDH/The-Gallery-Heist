extends "res://Scenes/Objects/Characters/Enemies/enemy.gd"

## the movement speed
@export var _wander_speed : float = 50.0
## if true this enemy will charge toward the player when spotted
@export var _is_charger : bool = false
## the chargning speed if charger is true
@export var _charge_speed : float = 100.0

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var _sprite : AnimatedSprite2D = $Sprite
@onready var _gap_detect_left : RayCast2D = $Detectors/GapDetectLeft
@onready var _gap_detect_right : RayCast2D = $Detectors/GapDetectRight
@onready var _debug_vars_visualizer : PanelContainer = $DebugVarsVisualizer
@onready var _obstacle_detect_left : RayCast2D = $Detectors/ObstacleDetectLeft
@onready var _obstacle_detect_right : RayCast2D = $Detectors/ObstacleDetectRight
#@onready var _player_detection = $Detectors/PlayerDetection

var _player : Player
var _player_detected : bool = false
var _state_machine : StateMachine = StateMachine.new()

func _ready():
	_max_health = 2
	_damage_cooldown_time = 1.0
	_health = _max_health
	_knockback = 130.0
	
	_gap_detect_left.add_exception(self)
	_gap_detect_right.add_exception(self)
	_obstacle_detect_left.add_exception(self)
	_obstacle_detect_right.add_exception(self)
	
	_debug_vars_visualizer.add_var("State")
	
	_state_machine.add_state("wander", _state_wander_switch_to, Callable(), Callable(), _state_wander_ph_process)
	_state_machine.add_state("charge",_state_charge_switch_to, Callable(), Callable(), _state_charge_ph_process)
	_state_machine.change_state("wander")
	
	await get_tree().process_frame
	_player = World.level.player
	
func _process(delta : float):
	super._process(delta)
	_state_machine.state_process(delta)
	
	_debug_vars_visualizer.edit_var("State", _state_machine.get_current_state())
	
	if _direction.x > 0:
		_sprite.flip_h = false

	elif _direction.x < 0:
		_sprite.flip_h = true

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)

func take_damage(damage : int, knockback_direction : Vector2, is_deadly : bool = false) -> bool:
	return super.take_damage(damage, knockback_direction, is_deadly)

func _state_wander_switch_to(from: String):
	velocity = Vector2(0,0) 
	_direction = Vector2(0,0)
	var _random_direction = randi()% 2
	match _random_direction:
		0: _direction.x = 1
		1: _direction.x = -1

func _state_wander_ph_process(delta: float):
	if not is_on_floor():
		velocity.y += _gravity * delta
	
	velocity.x = _direction.x * _wander_speed
	
	if is_on_floor():
		var velocity_sign : int = sign(velocity.x)
		if ((velocity_sign == 1 && _gap_detect_right.is_colliding() == false) ||
		(velocity_sign == -1 && _gap_detect_left.is_colliding() == false)) or ((velocity_sign == 1 && _obstacle_detect_right.is_colliding() == true) ||
		(velocity_sign == -1 && _obstacle_detect_left.is_colliding() == true)):
			_direction.x = -_direction.x
	
	if _player_detected == true and _is_charger == true:
		_state_machine.change_state("charge")
	
	move_and_slide()

func _state_charge_switch_to(from : String) :
	#TODO: He's suppose to hop up to telegraph his charge, maybe animated node will do better
	velocity = Vector2(0,0)
	velocity.y += 10
	move_and_slide()

func _state_charge_ph_process(delta : float) :
	_direction.x = _player.position.x - position.x
	velocity = _charge_speed * _direction.normalized()
	if not is_on_floor():
		velocity.y += _gravity * delta
	move_and_slide()
	if _player_detected == false:
		_state_machine.change_state("wander")


func _on_player_detection_body_exited(body):
	if body is Player :
		_player_detected = false


func _on_player_detection_body_entered(body):
	if body is Player :
		_player_detected = true
