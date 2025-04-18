@icon("../icons/ring-icon.png")
class_name Effect
extends Node3D

@export_node_path("AnimationPlayer", "GPUParticles3D") var effect_root: NodePath
@export var debug: bool

signal started()
signal finished()
signal stopped()

@onready var one_shot: bool:
	get:
		var _one_shot = false
		if _animation:
			var anim := _animation.get_animation(_animation.current_animation)
			if anim:
				_one_shot = (anim.loop_mode == Animation.LOOP_NONE)
				#_one_shot = animation.autoplay
			else:
				_one_shot = true
		if _particles:
			_one_shot = one_shot or _particles.one_shot
		return _one_shot
			

@onready var is_playing: bool:
	get:
		return (_particles and _particles.emitting) \
			or (_animation and _animation.is_playing())


var _animation: AnimationPlayer
var _particles: GPUParticles3D

func _ready() -> void:
	var animation_node: AnimationPlayer = get_node_or_null(effect_root) as AnimationPlayer
	
	# based on an animation?
	if animation_node:
		_animation = animation_node
		_animation.animation_finished.connect(_animation_finished)
		assert(_animation.autoplay=="", "Effects should not be autoplay, " + name + ", track:" + _animation.autoplay)
	
	# ...or particle node?
	var particles_node: GPUParticles3D = get_node_or_null(effect_root) as GPUParticles3D
	if particles_node:
		_particles = particles_node
		_particles.finished.connect(_particles_finished)
	
	assert(_particles or _animation, "Missing particles or animation root node")


# signal forwarding
func _animation_finished(_name: StringName):
	if _name == "start":
		finished.emit()


func _particles_finished():
	finished.emit()


## Start effect
func start():
	if _animation:
		_animation.play("start")
	if _particles:
		_particles.emitting = true
	started.emit()


## Stop effect immediately
func stop():
	if _animation:
		_animation.play("RESET")
	if _particles:
		_particles.emitting = false
	stopped.emit()


## Wait for one_shot effects or stop looping effects.
## Usage: [code]await my_effect.await_stop()[/code]
func await_stop():
	if is_playing and one_shot:
		#await self.finished
		await _animation.animation_finished
	else:
		stop()
