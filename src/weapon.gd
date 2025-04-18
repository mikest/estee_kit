@icon("../icons/sword-icon.png")
class_name Weapon
extends Item

## Weapon is a subclass of [Item] that is used to represent things that do damage.
##
## It has an optional [AttackComponent] which may be present in the scene tree with the name
## [code]%AttackComponent[/code]. Make sure you set [i]Access as Unique Name[/i] so it can be found.
##
## Weapons also include a [member attack_effect] which will be triggered on [method attack_start].
## This is useful for things like muzzle flash or flaming swords.
## [br][br]
##
## Weapons can also launch projectiles by attaching one to [member projectile_scene]. It will be launched
## from the [member launch_point] with a few degrees of [member projectile_jitter] if set. Projectile launching
## is separate from weapon attacks, so a ranged weapon can be used as a blunt instrument when out of ammo.
## [br][br]
##
## [img]res://addons/estee_kit/docs/example_weapon.png[/img]


## Effect to play at [method attack_start] or [method fire].
## NOTE: For [method fire] attacks, the effect must be a one_shot to stop on its own.
@export var attack_effect: Effect

@export_subgroup("Projectile Weapons")
@export var launch_point: Marker3D = null	## Launch point. Fires towards MODEL_FRONT
@export var projectile_scene: PackedScene = null	## Projectile to fire.
@export var projectile_count: int = -1		## Number of shots left. Set to -1 for infinite ammo.
@export_range(0,5,0.01,"radians_as_degrees") var projectile_jitter: float = 0.0 ## Random angular innaccuracy magnitude.

@onready var attack_component: AttackComponent = %AttackComponent  ## Optional attack. Needed for melee weapons.

var is_attacking: bool:
	get: return attack_component and attack_component.enabled

var can_attack: bool:
	get: return can_use

#region Runtime
## Call [code]super._ready()[/code] if you sublass.
func _ready():
	super._ready()	# Item
		
	if attack_effect:
		attack_effect.stop()
	
	# initial state
	attack_stop()
#endregion

## Fires projectile. Starts the attack effect.
func fire():
	if projectile_scene and (projectile_count != 0):
		var projectile: Projectile = projectile_scene.instantiate()
		if projectile:
			_get_level().add_child(projectile)
			
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
			
			# optional effect
			if attack_effect:
				attack_effect.start()
			
			# enabled
			projectile.attack_start()
			
			if projectile_count > 0:
				projectile_count -= 1


## Starts the attack effect and enables the AttackComponent if set.
func attack_start():
	if attack_component:
		attack_component.enabled = true
		
	if attack_effect:
		attack_effect.start()


## Stops the attack effect and disables the AttackComponent if set.	
func attack_stop():
	if attack_component:
		attack_component.enabled = false
		
	if attack_effect:
		attack_effect.stop()

	
