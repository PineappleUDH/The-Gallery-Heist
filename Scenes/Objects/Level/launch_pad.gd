@tool
extends Area2D

@onready var _launch_delay : Timer = $LaunchDelay
@onready var _animation : AnimatedSprite2D = $Animation
@export var _launch_force : float = 500.0 :
	set(value):
		_launch_force = max(value, 0.0)
		queue_redraw()
@export var _toggle_editor_preview : bool = true :
	set(value):
		_toggle_editor_preview = value
		queue_redraw()

const _preview_color : Color = Color("ffffff64")

# player uses same gravity value as project setting
var _player_gravity : float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _draw():
	if Engine.is_editor_hint() == false || _toggle_editor_preview == false:
		return
	
	var simulated_velocity : float = _launch_force
	var simulated_delta : float = get_process_delta_time()
	var highest_point : float = 0.0
	
	while simulated_velocity > 0:
		highest_point += simulated_velocity * simulated_delta
		simulated_velocity -= _player_gravity * simulated_delta
	
	# draw preview
	draw_dashed_line(
		Vector2.ZERO, Vector2(0, -highest_point), _preview_color, 3.0, 10.0
	)
	var hologram_tex : Texture2D = preload("res://Resources/Textures/Characters/SaulSprites/Preview.png")
	draw_texture(
		hologram_tex,
		Vector2(0, -highest_point) - hologram_tex.get_size() / 2.0,
	)

func _on_body_entered(body : Node2D):
	if body is Character && _launch_delay.is_stopped():
		body.velocity.y = -_launch_force
		_animation.play("pressed")
		
		if body is Player:
			body.refill_dash()
		
		_launch_delay.start()

func _on_launch_delay_timeout():
	_animation.play("default")
