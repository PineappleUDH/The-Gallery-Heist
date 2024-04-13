class_name Player
extends "res://Scenes/Objects/Characters/character.gd"

signal respawned
signal interacted

@onready var _cling_time : Timer = $Timers/ClingTime
@onready var _coyote_timer : Timer = $Timers/CoyoteTimer
@onready var _jump_buffer_timer : Timer = $Timers/JumpBufferTimer
@onready var _dash_cooldown : Timer = $Timers/DashCooldown
@onready var _dash_timer : Timer = $Timers/DashTimer
@onready var _footstep_timer : Timer = $Timers/FootstepTimer
@onready var _cancel_slide_delay : Timer = $Timers/CancelSlideDelay
@onready var _wall_grab_cooldown : Timer = $Timers/WallGrabCooldown

@onready var _dash_trail : Node2D = $DashTrail
#@onready var _dust_trail : GPUParticles2D = $DustTrail
@onready var _detect_right : RayCast2D = $Detection/Right
@onready var _detect_left : RayCast2D = $Detection/Left
@onready var _terrain_detector = $Detection/TerrainDetector
@onready var _hurtbox : Area2D = $HurtBox
@onready var _collider : CollisionShape2D = $CollisionShape2D
@onready var _sfx : Dictionary = {
	"jump":$Sounds/Jump, "dash":$Sounds/Dash, "hit_wall":$Sounds/HitWall,
	"attack":$Sounds/Attack, "died":$Sounds/Died, "footstep":$Sounds/Footstep,
	"slide":$Sounds/Slide
}
@onready var _sprite : AnimatedSprite2D = $Sprite
@onready var _debug_vars_visualizer : PanelContainer = $DebugVarsVisualizer

# TEMP
@onready var _attack_sprite : Sprite2D = $HurtBox/AttackSprite

# Set Variables for overall control feel
var _facing : Vector2 = Vector2.RIGHT
const _max_move_speed : float = 250.0
const _max_fall_speed : float = 800.0
const _accel : float = 450.0
const _decel : float = 600.0
const _jump_force : float = 260.0
const _run_anim_threshold : float = 150.0
const _attack_time : float = 0.2
var _attack_timer : float = _attack_time
const _slide_speed : float = 60.0
const _walk_footstep_time : float = 0.6
const _run_footstep_time : float = 0.3

var _can_dash : bool = true
const _dash_speed: float = 300
const _dash_shake_duration : float = 0.3

const _wall_jump_force : float = 260.0
const _wall_push_force : float = 230.0

const _damage_shake_duration : float = 0.3
var _player_score : float = 0 # TODO: move to level class

var _state_machine : StateMachine = StateMachine.new()

func _ready():
	_max_health = 4
	_damage_cooldown_time = 2.0
	_health = _max_health
	
	_state_machine.add_state("normal", Callable(), _state_normal_switch_from, _state_normal_process, _state_normal_ph_process)
	_state_machine.add_state("dash", _state_dash_switch_to, _state_dash_switch_from, Callable(), _state_dash_ph_process)
	_state_machine.add_state("wall_slide", _state_wall_slide_switch_to, _state_wall_slide_switch_from, Callable(), _state_wall_slide_ph_process)
	_state_machine.add_state("attack", _state_attack_switch_to, _state_attack_switch_from, Callable(), _state_attack_ph_process)
	_state_machine.add_state("swim", _state_swim_switch_to, _state_swim_switch_from,Callable(),_state_swim_ph_process)
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
	
	if (Input.is_action_just_pressed("interact") and
	_state_machine._curr_state != "dead"):
		interacted.emit()
	
	# debug
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
	
	global_position = checkpoint_position
	# wait for hurtbox Area2D to update its collision
	# otherwise objects that apply continuous damage like spikes
	# will damage player on respawn because they haven't yet
	# detected that player has exited them
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	_health = _max_health
	_facing = Vector2.RIGHT
	_direction = Vector2.RIGHT
	_player_score = 0
	_state_machine.change_state("normal")
	
	respawned.emit()

func get_facing() -> Vector2:
	return _facing

func _damage_taken(damage : int, die : bool):
	if die:
		_sfx["died"].play()
		_state_machine.call_deferred("change_state", "dead")
	else:
		World.level.level_camera.shake(LevelCamera.ShakeLevel.low, _damage_shake_duration)
		_damaged_sfx.play()
		
		if _state_machine.get_current_state() == "wall_slide":
			# stop wall slide on damage
			_state_machine.change_state("normal")
			return

# use instead of _sprite.play() to avoid replaying the same animation from the start when it's already playing
func _play_animation(anim_name : String, ignore_if_playing : bool = false):
	if ignore_if_playing && anim_name == _sprite.animation:
		return
	_sprite.play(anim_name)

func _get_ray_colliding_with_tilemap() -> RayCast2D:
	if _detect_left.is_colliding() and _detect_left.get_collider() is TileMap:
		return _detect_left
	elif _detect_right.is_colliding() and _detect_right.get_collider() is TileMap:
		return _detect_right
	return null

func _state_normal_switch_from(to : String):
	World.level.level_camera.player_look_offset(0)
	_coyote_timer.stop()
	_jump_buffer_timer.stop()
	_footstep_timer.stop()

func _state_normal_process(delta : float):
	# animation
	if is_on_floor():
		if velocity.x == 0:
			if _direction.y == 0:
				_play_animation("Idle")
			else:
				_play_animation("Looking Up" if _direction.y == -1 else "Looking Down")
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
		velocity.y = min(velocity.y + _gravity * delta, _max_fall_speed)
	
	# Movement Control
	_direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	if _direction: _facing = _direction
	
	if _direction.x:
		velocity.x = move_toward(velocity.x, _max_move_speed * sign(_direction.x), _accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, _decel * delta)
	
	# footsteps
	if is_on_floor() and _footstep_timer.is_stopped() and velocity.x:
		if _direction.x:
			_sfx["footstep"].play()
			if abs(velocity.x) > _run_anim_threshold:
				_footstep_timer.wait_time = _run_footstep_time
			else:
				_footstep_timer.wait_time = _walk_footstep_time
			
		else:
			#_footstep_timer.wait_time = ?
			#_sfx["slide"].play()
			pass
		
		_footstep_timer.start()
		
	
	if velocity.x == 0 && is_on_floor() && _direction.y:
		World.level.level_camera.player_look_offset(int(_direction.y))
	else:
		World.level.level_camera.player_look_offset(0)
	
	# jump
	var just_jumped : bool = false
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or not _coyote_timer.is_stopped():
			velocity.y = -_jump_force
			just_jumped = true
			_sfx["jump"].play()
		elif is_on_floor() == false:
			_jump_buffer_timer.start()
	
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
			just_jumped = true
			_sfx["jump"].play()
	
	if (is_on_floor() == false and Input.is_action_pressed("wall_grab") and
	_wall_grab_cooldown.is_stopped()):
		var ray : RayCast2D = _get_ray_colliding_with_tilemap()
		if ray :
			if ray == _detect_left:
				_facing = Vector2.LEFT
			elif ray == _detect_right:
				_facing = Vector2.RIGHT
			
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
		return

func _state_wall_slide_switch_to(from : String):
	velocity = Vector2(0,0)
	_cling_time.start()
	_play_animation("Cling")

func _state_wall_slide_switch_from(to : String):
	_cancel_slide_delay.stop()
	_wall_grab_cooldown.start()

func _state_wall_slide_ph_process(delta: float):
	if _cling_time.is_stopped():
		_play_animation("Sliding")
		if Input.is_action_pressed("down"):
			velocity.y = _slide_speed * 2
		else:
			velocity.y = _slide_speed
		
	
	# cancel sliding
	if Input.is_action_just_released("wall_grab"):
		_cancel_slide_delay.start()
	elif Input.is_action_pressed("wall_grab") == false and _cancel_slide_delay.is_stopped():
		_state_machine.change_state("normal")
		return
	
	if Input.is_action_just_pressed("dash") && _can_dash:
		_facing = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
		_state_machine.change_state("dash")
		return
	
	# jump off
	if Input.is_action_just_pressed("jump"):
		_sfx["jump"].play()
		_facing *= -1
		velocity.x = _wall_push_force * _facing.x
		velocity.y = -_wall_jump_force
		_play_animation("Wall Jump", true)
		_state_machine.change_state("normal")
		return
	
	# wall out of reach
	var ray : RayCast2D = _get_ray_colliding_with_tilemap()
	if (is_on_floor() or
	((_facing == Vector2.LEFT and ray != _detect_left) or (_facing == Vector2.RIGHT and ray != _detect_right))):
		_state_machine.change_state("normal")
		return
	
	move_and_slide()

func _state_dash_switch_to(from : String):
	World.level.level_camera.shake(LevelCamera.ShakeLevel.low, _dash_shake_duration)
	_can_dash = false
	velocity = Vector2.ZERO
	_dash_trail.set_active(true, _sprite.flip_h)
	_sfx["dash"].play()
	_dash_timer.start()
	_play_animation("Dashing")

func _state_dash_switch_from(to: String):
	_dash_cooldown.start()
	_dash_trail.set_active(false)

func _state_dash_ph_process(delta: float):
	velocity = _dash_speed * _facing.normalized()
	
	move_and_slide()
	
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
		velocity.y = min(velocity.y + _gravity * delta, _max_fall_speed)
	
	move_and_slide()
	
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = _attack_time
		_state_machine.change_state("normal")

func _state_swim_switch_to(from : String):
	pass

func _state_swim_switch_from(to : String):
	pass

func _state_swim_ph_process(delta):
	pass

func _state_dead_switch_to(from : String):
	velocity = Vector2.ZERO
	_collider.disabled = true
	_is_invincible = true
	_sprite.flip_h = false
	
	_play_animation("Die")
	await _sprite.animation_finished
	died.emit()

func _state_dead_switch_from(to : String):
	_collider.disabled = false
	_is_invincible = false

func _on_terrain_detector_body_entered(body):
	pass
