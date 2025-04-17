@tool
@icon("../icons/projectile-icon.png")
class_name ProjectileLauncher
extends Node3D

@export var projectile_scene: PackedScene = null

var should_launch: bool = false

func _ready():
	# instantiate a single projectile while in editor
	if projectile_scene and Engine.is_editor_hint():
		var temp := projectile_scene.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED) as Node3D
		if temp:
			add_child(temp)
			temp.global_transform = global_transform
			temp.top_level = false


func _physics_process(_delta: float):
	if not Engine.is_editor_hint():
		if should_launch:
			var projectile: Projectile = projectile_scene.instantiate() as Node3D
			add_child(projectile)
			projectile.global_transform = global_transform
			
			# a little bit of jitter
			projectile.rotate_y(deg_to_rad(randf_range(-1,1)))
			projectile.rotate_x(deg_to_rad(randf_range(-1,1)))
			projectile.force_update_transform()
			
			# initial velocity
			var direction := projectile.basis * Vector3.MODEL_FRONT * projectile.speed
			projectile.apply_impulse(direction)
			
			should_launch = false


func launch():
	should_launch = true
