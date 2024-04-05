extends Node2D

@onready var _launch_delay = $LaunchDelay
@onready var _animation = $Base/Animation
@export var _launch_force : float = 500.0

func _process(delta):
	if not _animation.is_playing():
		_animation.play("default")

func _on_activation_zone_body_entered(body):
	_launch_delay.start()
	await _launch_delay.is_stopped()
	body.velocity.y -= _launch_force
	_animation.play("pressed")
	
