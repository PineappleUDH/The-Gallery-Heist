class_name Player
extends "res://Scenes/Objects/Characters/character.gd"

signal respawned

@onready var _cling_time : Timer = $Timers/ClingTime
@onready var _coyote_timer : Timer = $Timers/CoyoteTimer
@onready var _jump_buffer_timer : Timer = $Timers/JumpBufferTimer
@onready var _slide_cancel_timer : Timer = $Timers/SlideCancelTimer
@onready var _dash_cooldown : Timer = $Timers/DashCooldown
@onready var _dash_timer : Timer = $Timers/DashTimer
@onready var _dash_trail : Line2D = $DashTrail
#@onready var _dust_trail : GPUParticles2D = $DustTrail
@onready var _slide_delay : Timer = $Timers/SlideDelay
@onready var _detect_right : RayCast2D = $Detection/Right
@onready var _detect_left : RayCast2D = $Detection/Left
@onready var _hurtbox : Area2D = $HurtBox
@onready var _collider : CollisionShape2D = $CollisionShape2D
@onready var _sfx : Dictionary = {
	"jump":$Sounds/Jump, "dash":$Sounds/Dash, "hit_wall":$Sounds/HitWall,
	"attack":$Sounds/Attack, "died":$Sounds/Died
}
@onready var _sprite : AnimatedSprite2D = $Sprite
@onready var _debug_vars_visualizer : PanelContainer = $DebugVarsVisualizer
const _dash_sprite : PackedScene = preload("res://Scenes/Objects/Characters/Saul/dash_sprite.tscn")

# TEMP
@onready var _attack_sprite : Sprite2D = $HurtBox/AttackSprite

# Set Variables for overall control feel
var _facing : Vector2 = Vector2.RIGHT
const _max_move_speed : float = 250.0
const _accel : float = 450.0
const _decel : float = 600.0
const _jump_force : float = 260.0
const _run_anim_threshold : float = 150.0
const _attack_time : float = 0.2
var _attack_timer : float = _attack_time
const _slide_speed : float = 60

var _can_dash : bool = true
const _dash_speed: float = 300
const _dash_shake_duration : float = 0.2

const _wall_jump_force : float = 260.0
const _wall_push_force_high : float = 230.0
const _wall_push_force_low : float = 100.0

const _damage_shake_duration : float = 0.3
var _player_score : float = 0 # TODO: move to lavel class

var _state_machine : StateMachine = StateMachine.new()

func _ready():
	_max_health = 4
	_damage_cooldown_time = 2.0
	_health = _max_health
	
	_state_machine.add_state("normal", Callable(), Callable(), _state_normal_process, _state_normal_ph_process)
	_state_machine.add_state("dash", _state_dash_switch_to, _state_dash_switch_from, Callable(), _state_dash_ph_process)
	_state_machine.add_state("wall_slide", _state_wall_slide_switch_to, _state_wall_slide_switch_from, Callable(), _state_wall_slide_ph_process)
	_state_machine.add_state("attack", _state_attack_switch_to, _state_attack_switch_from, Callable(), _state_attack_ph_process)
	_state_machine.add_state("dead", _state_dead_switch_to, _state_dead_switch_from, Callable(), Callable())
	_state_machine.change_state("normal")
	
	_debug_vars_visualizer.add_var("Score")
	_debug_vars_visualizer.add_var("State")
	_debug_vars_visualizer.add_var("Can_Dash")
	_debug_vars_visualizer.add_var("Health")

func _process(delta : float):
	super._process(delta)
	_state_machine.state_process(delta)
	if _facing.x > 0:
		_sprite.flip_h = false
	if _facing.x < 0:
		_sprite.flip_h = true
	
	_debug_vars_visualizer.edit_var("Score", _player_score)
	_debug_vars_visualizer.edit_var("State", _state_machine.get_current_state())
	_debug_vars_visualizer.edit_var("Can_Dash", _can_dash)
	_debug_vars_visualizer.edit_var("Health", str(_health) + "/" + str(_max_health))

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)

func add_score(amount : float):
	_player_score += amount
	if amount > 1 :
		if _health < _max_health:
			_health += 1
	World.current_score = _player_score

func can_dash():
	return _can_dash

func refill_dash():
	if _can_dash == false:
		_can_dash = true
		_dash_cooldown.stop()

func take_damage(damage : int, knockback : float, from : Vector2, is_deadly : bool = false):
	super.take_damage(damage, knockback, from, is_deadly)

func reset_from_checkpoint(checkpoint_position : Vector2):
	assert(_state_machine.get_current_state() == "dead")
	
	_health = _max_health
	_facing = Vector2.RIGHT
	_direction = Vector2.RIGHT
	_player_score = 0
	global_position = checkpoint_position
	_state_machine.change_state("normal")
	
	respawned.emit()

# This is in place to pass the input value to other things that players expect to
# respond to input such as attack direction
func get_direction() -> Vector2:
	return _direction

func _damage_taken(damage : int, die : bool):
	if die:
		_sfx["died"].play()
		_state_machine.call_deferred("change_state", "dead")
	else:
		World.level.level_camera.shake(LevelCamera.ShakeLevel.low, _damage_shake_duration)
		_damaged_sfx.play()

# use instead of _sprite.play() to avoid replaying the same animation from the start when it's already playing
func _play_animation(anim_name : String, ignore_if_playing : bool = false):
	if ignore_if_playing && anim_name == _sprite.animation:
		return
	_sprite.play(anim_name)

func _state_normal_switch_from(to : String):
	World.level.level_camera.y_look_offset(0)
	_coyote_timer.stop()
	_jump_buffer_timer.stop()

func _state_normal_process(delta : float):
	# animation
	if is_on_floor():
		if velocity.x == 0:
			_play_animation("Idle")
		elif abs(velocity.x) > _run_anim_threshold:
			var x_input_dir : float = Input.get_axis("left", "right")
			if sign(x_input_dir) == sign(velocity.x):
				_play_animation("Run")
			else:
				_play_animation("Skidding")
		else:
			_play_animation("Walk")
		
	else:
		if velocity.y > 0:
			_play_animation("Falling", true)
		else:
			_play_animation("Jump", true)
	
func _state_normal_ph_process(delta : float):
	# Enable gravity.
	if not is_on_floor():
		velocity.y += _gravity * delta
	
	# Movement Control
	_direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	if _direction: _facing = _direction
	
	if _direction.x:
		velocity.x = move_toward(velocity.x, _max_move_speed * sign(_direction.x), _accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, _decel * delta)
	
	if velocity.x == 0 && is_on_floor() && _direction.y != 0:
		# TODO: some "looking up" and down animations would be nice
		World.level.level_camera.player_look_offset(_direction.y)
	else:
		World.level.level_camera.player_look_offset(0)
	
	# Allow player to jump
	var just_jumped : bool = false
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or not _coyote_timer.is_stopped():
			velocity.y = -_jump_force
			just_jumped = true
			_sfx["jump"].play()
		elif is_on_floor() == false:
			_jump_buffer_timer.start()
	
	# Engage physics engine
	var was_on_floor = is_on_floor()
	move_and_slide()
	
	# Coyote Timer
	if was_on_floor and is_on_floor() == false:
		if just_jumped == false:
			# just fell off
			_coyote_timer.start()
	elif was_on_floor == false and is_on_floor():
		# just landed
		_play_animation("Landing")
		if _jump_buffer_timer.is_stopped() == false:
			velocity.y = -_jump_force
	
	# TODO: is_on_wall is true when climbing on other bodies, should ensure we're only clinging to tiles
	if is_on_wall() == true \
		and is_on_floor() == false\
		and _slide_delay.is_stopped() \
		and (_detect_left.is_colliding() \
		or _detect_right.is_colliding()):
		_sfx["hit_wall"].play()
		_state_machine.change_state("wall_slide")
		return
	
	if _can_dash == false && _dash_cooldown.is_stopped() && is_on_floor():
		_can_dash = true
	
	if Input.is_action_just_pressed("dash") && _can_dash:
		_state_machine.change_state("dash")
		return
	
	if Input.is_action_just_pressed("attack_basic"):
		_state_machine.change_state("attack")

func _state_wall_slide_switch_to(from : String):
	_facing = Vector2.LEFT if _detect_left.is_colliding() else Vector2.RIGHT
	velocity = Vector2(0,0)
	_cling_time.start()
	_play_animation("Cling")

func _state_wall_slide_switch_from(to : String):
	_facing *= -1
	_slide_cancel_timer.stop()
	_slide_delay.start()

func _state_wall_slide_ph_process(delta: float):
	if _cling_time.is_stopped():
		_play_animation("Sliding")
		velocity.y = _slide_speed
	
	# jump off
	if Input.is_action_just_pressed("jump"):
		_sfx["jump"].play()
		velocity.x = _wall_push_force_high * -_facing.x
		velocity.y = -_wall_jump_force
		_play_animation("Wall Jump", true)
		_state_machine.change_state("normal")
		return
	
	# wall out of reach
	if (is_on_floor() or
	(_detect_left.is_colliding() == false and _detect_right.is_colliding() == false)):
		_state_machine.change_state("normal")
		return
	
	var opposite_dir_input : String = "left" if _facing.x == 1 else "right"
	if Input.is_action_just_pressed(opposite_dir_input):
		_slide_cancel_timer.start()
	elif Input.is_action_just_released(opposite_dir_input):
		_slide_cancel_timer.stop()
	
	# cancel sliding
	elif (Input.is_action_just_pressed("down") or
	(Input.is_action_pressed(opposite_dir_input) and _slide_cancel_timer.is_stopped())):
		velocity.x = _wall_push_force_low * -_facing.x
		_state_machine.change_state("normal")
		return
	
	move_and_slide()

func _state_dash_switch_to(from : String):
	World.level.level_camera.shake(LevelCamera.ShakeLevel.low, _dash_shake_duration)
	_can_dash = false
	_sfx["dash"].play()
	#_dash_trail.set_active(true)
	_dash_timer.start()
	velocity = Vector2.ZERO
	_sprite.play("Dashing")

func _state_dash_switch_from(to: String):
	_dash_cooldown.start()
	#_dash_trail.set_active(false)

func _state_dash_ph_process(delta: float):
	_direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	velocity = _dash_speed * _facing.normalized()
	
	move_and_slide()
	
	var _dash_smear = _dash_sprite.instantiate()
	_dash_smear.global_position = global_position
	_dash_smear.flip_h = _sprite.flip_h
	get_parent().add_child(_dash_smear)
	
	if _dash_timer.is_stopped() or is_on_wall():
		_dash_timer.stop()
		_state_machine.change_state("normal")
		return

func _state_attack_switch_to(from : String):
	_attack_sprite.visible = true
	_hurtbox.scale.x = 1 if !_sprite.flip_h else -1
	_hurtbox.monitoring = true
	_sfx["attack"].play()

func _state_attack_switch_from(from : String):
	_attack_sprite.visible = false
	_hurtbox.monitoring = false

func _state_attack_ph_process(delta: float):
	# Enable gravity.
	if not is_on_floor():
		velocity.y += _gravity * delta
	
	move_and_slide()
	
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = _attack_time
		_state_machine.change_state("normal")

func _state_dead_switch_to(from : String):
	velocity = Vector2.ZERO
	_collider.disabled = true
	_is_invincible = true
	# TODO: death animation, player can die both on ground and in mid-air
	died.emit()

func _state_dead_switch_from(to : String):
	_collider.disabled = false
	_is_invincible = false
