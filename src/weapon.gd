@icon("../icons/sword-icon.png")
class_name Weapon
extends Item

## Weapon
##
## An item that has an AttackComponent
##

## Seconds between use
@export var attack_effect: Effect

@export_subgroup("Projectile Weapons")
@export var launch_point: Marker3D = null
@export var projectile_scene: PackedScene = null
@export_range(0,5,0.01,"radians_as_degrees") var projectile_jitter: float = 0.0

@onready var attack_component: AttackComponent = %AttackComponent

var is_attacking: bool:
	get: return attack_component.enabled

var can_attack: bool:
	get: return can_use

#region Runtime
func _ready():
	super._ready()	# Item
	assert(attack_component, "Missing %AttackComponent!")
		
	if attack_effect:
		attack_effect.stop()
	
	# initial state
	attack_stop()
#endregion

# for projectile weapons
func fire():
	if projectile_scene:
		var projectile: Projectile = projectile_scene.instantiate()
		if projectile:
			var main: Node3D = get_tree().current_scene
			main.level.add_child(projectile)
			
			if launch_point:
				projectile.global_transform = launch_point.global_transform
			else:
				projectile.global_transform = global_transform
			
			# a little bit of jitter
			projectile.rotate_y(deg_to_rad(randf_range(-projectile_jitter,projectile_jitter)))
			projectile.rotate_x(deg_to_rad(randf_range(-projectile_jitter,projectile_jitter)))
			
			# initial velocity
			var direction := projectile.basis * Vector3.MODEL_FRONT * projectile.speed
			projectile.force_update_transform()
			projectile.apply_impulse(direction)
			
			# enabled
			projectile.attack_start()

func attack_start():
	if attack_component:
		attack_component.enabled = true
		if attack_effect:
			attack_effect.start()
	
func attack_stop():
	if attack_component:
		attack_component.enabled = false
		if attack_effect:
			attack_effect.stop()

	
