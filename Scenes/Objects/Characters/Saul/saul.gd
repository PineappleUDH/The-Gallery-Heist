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
@onready var _water_timer : Timer = $Timers/WaterTimer

@onready var _sprite : AnimatedSprite2D = $Sprite
@onready var _dash_trail : Node2D = $DashTrail
@onready var _detect_right : RayCast2D = $Detection/Right
@onready var _detect_left : RayCast2D = $Detection/Left
@onready var _hurtbox : Area2D = $HurtBox
var _default_collider_size : Vector2
@onready var _sfx : Dictionary = {
	"jump":$Sounds/Jump, "dash":$Sounds/Dash, "hit_wall":$Sounds/HitWall,
	"attack":$Sounds/Attack, "died":$Sounds/Died, "footstep":$Sounds/Footstep,
	"slide":$Sounds/Slide
}

@onready var _walk_dust_particles : GPUParticles2D = $Particles/WalkDust
@onready var _slide_dust_particles : GPUParticles2D = $Particles/SlideDust
@onready var _jump_particles : GPUParticles2D = $Particles/Jump
@onready var _damage_particles : GPUParticles2D = $Particles/Damge
@onready var _bubbles_particles : GPUParticles2D = $Particles/Bubbles

# TEMP
@onready var _attack_sprite : Sprite2D = $HurtBox/AttackSprite

# Set Variables for overall control feel
var _facing : Vector2 = Vector2.RIGHT
const _max_move_speed : float = 250.0
const _max_fall_speed : float = 800.0
const _accel : float = 450.0
const _decel : float = 1000.0
const _jump_force : float = 260.0
const _run_anim_threshold : float = 150.0
const _attack_time : float = 0.2
var _attack_timer : float = _attack_time
const _slide_speed : float = 60.0
const _slide_speed_fast : float = 120.0
const _walk_footstep_time : float = 0.6
const _run_footstep_time : float = 0.3

const _water_gravity : float = 250.0
const _max_swim_speed : float = 190.0
const _out_of_water_push : float = 80.0
const _water_accel : float = 320.0
const _water_decel : float = 400.0
const _max_air : int = 5
var _air : int = _max_air
var _was_on_water_surface : bool = false
const _water_collider_size : Vector2 = Vector2(28, 14)

var _can_dash : bool = true
var _dash_disabled : bool = false
const _dash_speed: float = 300
const _dash_shake_duration : float = 0.3

const _wall_jump_force : float = 260.0
const _wall_push_force : float = 230.0

const _damage_shake_duration : float = 0.3

var _state_machine : StateMachine = StateMachine.new()

func _ready():
	_max_health = 4
	_damage_cooldown_time = 2.0
	_health = _max_health
	_knockback = 130.0
	
	_default_collider_size = _collider.shape.size
	
	_state_machine.add_state("normal", Callable(), _state_normal_switch_from, _state_normal_process, _state_normal_ph_process)
	_state_machine.add_state("dash", _state_dash_switch_to, _state_dash_switch_from, Callable(), _state_dash_ph_process)
	_state_machine.add_state("wall_slide", _state_wall_slide_switch_to, _state_wall_slide_switch_from, Callable(), _state_wall_slide_ph_process)
	_state_machine.add_state("attack", _state_attack_switch_to, _state_attack_switch_from, Callable(), _state_attack_ph_process)
	_state_machine.add_state("swim", _state_swim_switch_to, _state_swim_switch_from,Callable(),_state_swim_ph_process)
	_state_machine.add_state("dead", _state_dead_switch_to, _state_dead_switch_from, Callable(), Callable())
	_state_machine.change_state("normal")
	
	await get_tree().process_frame # wait for level to get ready
	World.level.interface.setup(_max_health, _max_air)

func _process(delta : float):
	super._process(delta)
	_state_machine.state_process(delta)
	if _facing.x > 0:
		_sprite.flip_h = false
	if _facing.x < 0:
		_sprite.flip_h = true
	
	if _state_machine._curr_state != "dead":
		# interaction
		if Input.is_action_just_pressed("interact"):
			interacted.emit()
		
		# check water
		if _state_machine._curr_state != "swim" && _is_water_tile(global_position):
			_state_machine.change_state("swim")

func _physics_process(delta : float):
	_state_machine.state_physics_process(delta)

func can_dash():
	return _can_dash

func refill_dash():
	if _can_dash == false && _dash_disabled == false:
		_set_can_dash(true)
		_dash_cooldown.stop()

func set_dash_disabled(disabled : bool):
	if disabled == _dash_disabled: return
	
	_dash_disabled = disabled
	World.level.interface.set_dash_locked(disabled)
	if _dash_disabled:
		_set_can_dash(false)

func heal(amount : int):
	if _health == _max_health: return
	
	var old_health : int = _health
	_health = min(_health + amount, _max_health)
	World.level.interface.set_health(old_health, _health)

func take_damage(damage : int, from : Vector2, is_deadly : bool = false) -> bool:
	var old_health : int = _health
	var applied : bool = super.take_damage(damage, from, is_deadly)
	
	World.level.interface.set_health(old_health, _health)
	return applied

func reset_from_checkpoint(checkpoint_position : Vector2):
	assert(_state_machine.get_current_state() == "dead")
	
	global_position = checkpoint_position
	# wait for hurtbox Area2D to update its collision
	# otherwise objects that apply continuous damage like spikes
	# will damage player on respawn because they haven't yet
	# detected that player has exited them
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	World.level.interface.set_health(_health, _max_health)
	_health = _max_health
	_facing = Vector2.RIGHT
	_direction = Vector2.RIGHT
	_dash_disabled = false
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
		_damage_particles.restart()
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

func _get_ray_colliding_with_tilemap() -> Vector2:
	if _detect_left.is_colliding() and _detect_left.get_collider() is TileMap:
		return Vector2.LEFT
	elif _detect_right.is_colliding() and _detect_right.get_collider() is TileMap:
		return Vector2.RIGHT
	return Vector2.ZERO

func _is_water_tile(global_pos : Vector2) -> bool:
	var layers_count : int = World.level.tilemap.get_layers_count()
	for i in layers_count:
		# check all layers for a water tile. pros:doesn't require custom tilemap setup
		#                                    const: additional processing
		var data : TileData = World.level.tilemap.get_cell_tile_data(
			i, World.level.tilemap.local_to_map(global_pos)
		)
		if data && data.get_custom_data("water") == true:
			return true
	
	return false

func _set_can_dash(can_dash : bool):
	_can_dash = can_dash
	World.level.interface.set_dash(can_dash)

func _state_normal_switch_from(to : String):
	World.level.level_camera.player_look_offset(0)
	_walk_dust_particles.emitting = false
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
		velocity.y = Utilities.soft_clamp(velocity.y, _gravity * delta, _max_fall_speed)
	
	# Movement Control
	_direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	if _direction: _facing = _direction
	
	if _direction.x:
		velocity.x = Utilities.soft_clamp(velocity.x, _accel * delta * sign(_direction.x), _max_move_speed)
	else:
		velocity.x = Utilities.soft_clamp(velocity.x, _decel * delta * -sign(velocity.x), 0.0)
	
	_walk_dust_particles.emitting = is_on_floor() and velocity.x
	
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
			velocity.y = Utilities.soft_clamp(velocity.y, -_jump_force, _jump_force)
			just_jumped = true
			_jump_particles.restart()
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
			velocity.y = Utilities.soft_clamp(velocity.y, -_jump_force, _jump_force)
			just_jumped = true
			_jump_particles.restart()
			_sfx["jump"].play()
	
	if (is_on_floor() == false and Input.is_action_pressed("wall_grab") and
	_wall_grab_cooldown.is_stopped()):
		var ray_dir : Vector2 = _get_ray_colliding_with_tilemap()
		if ray_dir != Vector2.ZERO:
			_facing = ray_dir
			
			_sfx["hit_wall"].play()
			_state_machine.change_state("wall_slide")
			return
	
	if (_can_dash == false && _dash_disabled == false &&
	_dash_cooldown.is_stopped() && is_on_floor()):
		_set_can_dash(true)
	
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
	_slide_dust_particles.emitting = false
	_cancel_slide_delay.stop()
	_wall_grab_cooldown.start()

func _state_wall_slide_ph_process(delta: float):
	if _cling_time.is_stopped():
		_slide_dust_particles.emitting = true
		_play_animation("Sliding")
		if Input.is_action_pressed("down"):
			velocity.y = _slide_speed_fast
		else:
			velocity.y =  _slide_speed
	
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
	var ray_dir : Vector2 = _get_ray_colliding_with_tilemap()
	if is_on_floor() or (_facing != ray_dir):
		_state_machine.change_state("normal")
		return
	
	move_and_slide()

func _state_dash_switch_to(from : String):
	World.level.level_camera.shake(LevelCamera.ShakeLevel.low, _dash_shake_duration)
	_set_can_dash(false)
	velocity = _dash_speed * _facing.normalized()
	_dash_trail.set_active(true, _sprite.flip_h)
	_sfx["dash"].play()
	_dash_timer.start()
	_play_animation("Dashing")

func _state_dash_switch_from(to: String):
	_dash_cooldown.start()
	_dash_trail.set_active(false)

func _state_dash_ph_process(delta: float):
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
		velocity.y = Utilities.soft_clamp(velocity.y, _gravity * delta, _max_fall_speed)
	
	move_and_slide()
	
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = _attack_time
		_state_machine.change_state("normal")

func _state_swim_switch_to(from : String):
	# limit enter speed so if player is going super fast a damp effect is applied like real life
	velocity = velocity.clamp(Vector2.ONE * -_max_swim_speed, Vector2.ONE * _max_swim_speed)
	
	_collider.shape.size = _water_collider_size
	_was_on_water_surface = true
	refill_dash()
	
	# TODO: muffle some sounds, would need to separate buses

func _state_swim_switch_from(to : String):
	# if player leaves water with a slow speed they'll fall right back leading to state continuously
	# changing. this kicks the player up when they leave
	velocity.y = Utilities.soft_clamp(velocity.y, -_out_of_water_push, _out_of_water_push)
	
	_collider.shape.size = _default_collider_size
	_bubbles_particles.emitting = false
	World.level.interface.set_air_active(false)
	World.level.interface.set_air(_air, _max_air)
	_air = _max_air
	_water_timer.stop()

func _state_swim_ph_process(delta : float):
	# Movement Control
	_direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	if _direction: _facing = _direction
	
	if _direction.x:
		velocity.x = Utilities.soft_clamp(velocity.x, _water_accel * sign(_direction.x) * delta, _max_swim_speed)
	else:
		velocity.x = Utilities.soft_clamp(velocity.x, _water_decel * delta * -sign(velocity.x), 0.0)
	
	if _direction.y:
		velocity.y = Utilities.soft_clamp(velocity.y, _max_swim_speed * sign(_direction.y) * delta, _max_swim_speed)
	else:
		velocity.y = Utilities.soft_clamp(velocity.y, _water_decel * delta * -sign(velocity.y), 0.0)
	
	if velocity != Vector2.ZERO:
		_play_animation("Water Swim")
	else:
		_play_animation("Water Idle")
	
	move_and_slide()
	
	# surface
	var is_on_surface : bool =\
		_is_water_tile(global_position - Vector2(0.0, World.level.tile_size)) == false
	var is_close_to_surface : bool =\
		# are you happy val? :(((((((
		_is_water_tile(global_position - Vector2(0.0, World.level.tile_size * 3)) == false
	
	_bubbles_particles.emitting = (is_on_surface == false and is_close_to_surface == false)
	
	if is_close_to_surface && Input.is_action_just_pressed("jump"):
		# TODO: repurpose jump buffer timer for this
		# sfx
		velocity.y = Utilities.soft_clamp(velocity.y, -_jump_force, _jump_force)
	
	if is_on_surface:
		if _was_on_water_surface == false:
			# just reached surface
			World.level.interface.set_air(_air, _max_air)
			_air = _max_air
			World.level.interface.set_air_active(false)
			_water_timer.stop()
	else:
		if _was_on_water_surface:
			# just sank below surface
			World.level.interface.set_air_active(true)
			_water_timer.start()
		
		if _water_timer.is_stopped():
			_water_timer.start()
			if _air > 0:
				World.level.interface.set_air(_air, _air-1)
				_air -= 1
			else:
				# damage time :)
				take_damage(1, Vector2.DOWN)
	
	_was_on_water_surface = is_on_surface
	
	# check out of water
	if _is_water_tile(global_position) == false:
		_state_machine.change_state("normal")

func _state_dead_switch_to(from : String):
	velocity = Vector2.ZERO # TODO: zoom in
	_collider.disabled = true
	_is_invincible = true
	_sprite.flip_h = false
	
	_play_animation("Die")
	await _sprite.animation_finished
	died.emit()

func _state_dead_switch_from(to : String):
	_collider.disabled = false
	_is_invincible = false
