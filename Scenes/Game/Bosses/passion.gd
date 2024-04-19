extends CharacterBody2D


@onready var _animation = $AnimationPlayer
@onready var _debug_vars_visualizer = $DebugVarsVisualizer
var _player_detected : bool = false
var _state_machine : StateMachine = StateMachine.new()
var _direction : Vector2
var _player : Player


func _ready():
	_state_machine.add_state("idle",Callable(),Callable(),_state_idle_process,Callable())
	_state_machine.add_state("combat",_state_combat_switch_to,_state_combat_switch_from,_state_combat_process,Callable())
	_state_machine.add_state("hiding",_state_hiding_switch_to,_state_hiding_switch_from,_state_hiding_process,Callable())
	_state_machine.add_state("attack",Callable(),Callable(),Callable(),Callable())
	_state_machine.add_state("spawn_flame",Callable(),Callable(),Callable(),Callable())
	_state_machine.change_state("idle")
	
	_debug_vars_visualizer.add_var("State")
	await get_tree().process_frame
	_player = World.level.player



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_state_machine.state_process(delta)
	_debug_vars_visualizer.edit_var("State", _state_machine.get_current_state())
	

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)
	

func _state_idle_process(delta : float):
	if _player_detected == true :
		_state_machine.change_state("combat")
	
func _state_combat_switch_to(from : String):
	if from == "idle" :
		_animation.play("Sparking")
	
func _state_combat_process(delta : float):
	if _animation.is_playing() == false:
		_animation.play("BurningIdle")
	if _player_detected == false :
		_state_machine.change_state("hiding")

func _state_combat_switch_from(to : String):
	if to == "hiding":
		_animation.play("BurningLaugh")


func _state_hiding_switch_to(from : String):
	_animation.play("Hiding")
	
func _state_hiding_process(delta: float):
	if _player_detected == true :
		_state_machine.change_state("combat")

func _state_hiding_switch_from(to : String):
	_animation.play("Emerging")

func _on_detection_body_entered(body):
	if body is Player :
		_player_detected = true

func _on_detection_body_exited(body):
	if body is Player :
		_player_detected = false
