# Copyright (c) 2024-2025 M. Estee
# MIT License

@icon("../icons/ring-icon.png")
extends Path3D
class_name PathFollower

#
# Moves an object along a path.
#

@onready var follower: PathFollow3D = $PathFollow3D
@onready var body: RigidBody3D = $RigidBody3D

var running: bool = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if running:
		follower.progress_ratio += delta * 0.1
		
		body.linear_velocity = (follower.global_position - body.global_position) * 5
		body.angular_velocity.y = wrapf(follower.global_rotation.y - body.global_rotation.y, -PI, PI) * 4
	pass

func _on_switch_pedestal_on_switch_activated(_switch):
	running = not running
