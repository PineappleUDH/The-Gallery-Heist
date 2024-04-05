extends Node2D

@onready var _launch_delay : Timer = $LaunchDelay
@onready var _animation : AnimatedSprite2D = $Base/Animation
@export var _launch_force : float = 500.0


# TODO: player can jump white in air after being launched due to koyote time
#       similar issues for Characters that set the velocity directly (velocity = ..) which cancels the push
#       maybe add a new function to the Character base class "apply_force(Vector2)"
#       which the player reacts to by disabling koyote time..
func _on_activation_zone_body_entered(body : Node2D):
	if body is Character && _launch_delay.is_stopped():
		body.velocity.y -= _launch_force
		_animation.play("pressed")
		
		if body is Player:
			body.refill_dash()
		
		_launch_delay.start()

func _on_launch_delay_timeout():
	_animation.play("default")
