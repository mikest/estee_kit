@tool
@icon("../icons/ring-icon.png")
class_name Effect
extends Node3D

@onready var animation: AnimationPlayer
@onready var particles: GPUParticles3D
@export var debug: bool

signal started()
signal finished()
signal stopped()

@export var one_shot: bool:
	get:
		one_shot = false
		if animation:
			var anim := animation.get_animation(animation.current_animation)
			if anim:
				one_shot = anim.loop_mode == Animation.LOOP_NONE
			else:
				one_shot = true
		if particles:
			one_shot = one_shot or particles.one_shot
		return one_shot
	set(val):
		if particles:
			particles.one_shot = val
		if animation:
			var anim := animation.get_animation(animation.current_animation)
			if anim:
				if val:
					anim.loop_mode = Animation.LOOP_NONE
				else:
					anim.loop_mode = Animation.LOOP_LINEAR
			

@export var is_playing: bool:
	get:
		return (particles and particles.emitting) \
			or (animation and animation.is_playing())
	set(val):
		if val:
			start()
		else:
			stop()

func _ready() -> void:
	# optional animation node
	var anim_node: AnimationPlayer = find_child("AnimationPlayer")
	if not animation and anim_node:
		animation = anim_node
		animation.animation_finished.connect(_animation_finished)
	
	# optional particle node
	var part_node: GPUParticles3D = find_child("GPUParticles3D")
	if not particles and part_node:
		particles = part_node
		particles.finished.connect(_particles_finished)

# signal forwarding
func _animation_finished(_name: String):
	finished.emit()

func _particles_finished():
	finished.emit()

# control
func start():
	if animation:
		animation.play("start")
	if particles:
		particles.emitting = true
	started.emit()

func stop():
	if animation:
		animation.play("RESET")
	if particles:
		particles.emitting = false
	stopped.emit()
