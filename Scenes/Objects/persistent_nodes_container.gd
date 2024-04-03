@tool
extends Node

# all children of this node will keep alive after parent has been freed
# this ensures sfx, particles etc.. keep playing for a while after the parent
# is gone

enum _KillType {none, timer, audio, audio2d, particles_cpu, particles_gpu}

@export var _kill_type : _KillType = _KillType.none :
	set(value):
		_kill_type = value
		notify_property_list_changed()
@export_group("Kill Trigger")
@export var _kill_time : float = 0.0
@export var _kill_audio : AudioStreamPlayer
@export var _kill_audio2d : AudioStreamPlayer2D
@export var _kill_particles : CPUParticles2D
@export var _kill_particles_gpu : GPUParticles2D


# I hate having a public function for this, tried listening for
# parent's tree_exiting signal but children get freed first :(
func detach():
	# see you nerds!
	reparent(get_tree().current_scene)
	
	if _kill_type == _KillType.none: return
	
	match _kill_type:
		_KillType.timer:
			await get_tree().create_timer(_kill_time).timeout
		_KillType.audio:
			assert(_kill_audio)
			await _kill_audio.finished
		_KillType.audio2d:
			assert(_kill_audio2d)
			await _kill_audio2d.finished
		_KillType.particles_cpu:
			assert(_kill_particles)
			await _kill_particles.finished
		_KillType.particles_gpu:
			assert(_kill_particles_gpu)
			await _kill_particles_gpu.finished
	
	queue_free()

func _validate_property(property : Dictionary):
	var name_ : String = property["name"]
	if name_ == "_kill_time" && _kill_type != _KillType.timer:
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
	elif name_ == "_kill_audio" && _kill_type != _KillType.audio:
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
	elif name_ == "_kill_audio2d" && _kill_type != _KillType.audio2d:
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
	elif name_ == "_kill_particles" && _kill_type != _KillType.particles_cpu:
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
	elif name_ == "_kill_particles_gpu" && _kill_type != _KillType.particles_gpu:
		property["usage"] = PROPERTY_USAGE_NO_EDITOR
