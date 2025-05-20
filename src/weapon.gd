@tool
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
@export var attack_component: AttackComponent  ## Optional attack. Needed for melee weapons.

@export_subgroup("Projectile Weapons")
@export var launch_point: Marker3D = null	## Launch point. Fires towards MODEL_FRONT
@export var projectile_scene: PackedScene = null	## Projectile to fire.
@export var projectile_count: int = -1		## Number of shots left. Set to -1 for infinite ammo.
@export_range(0,45,0.01,"radians_as_degrees") var spread_jitter: float = 0.0 ## Spread angle jitter amount.
@export_range(0,45,0.01,"radians_as_degrees") var height_jitter: float = 0.0 ## Arc height jitter amount

var is_attacking: bool:
	get: return attack_component and attack_component.enabled

var can_attack: bool:
	get: return can_use

#region Runtime
## Call [code]super._ready()[/code] if you sublass.
func _ready():
	super._ready()	# Item
	
	# tooliong
	if Engine.is_editor_hint():
		_rebuild_dummy_arrow()
		return
	
	# default
	if not attack_component:
		attack_component = get_node_or_null("AttackComponent") as AttackComponent
		
	if attack_effect:
		attack_effect.stop()
	
	# initial state
	attack_stop()
#endregion

## Fires projectile. Starts the attack effect.
func fire():
	if Engine.is_editor_hint(): return
	
	# cooldown, etc.
	reset_cooldown()
	
	if projectile_scene and (projectile_count != 0):
		var projectile: Projectile = projectile_scene.instantiate()
		if projectile:
			_get_level().add_child(projectile)
			
			var launch_basis: Basis = projectile.global_basis
			projectile.global_transform = global_transform
			
			if launch_point:
				projectile.global_transform = launch_point.global_transform
				launch_basis = launch_point.global_basis
			else:
				projectile.global_transform = global_transform
				launch_basis = projectile.global_basis
			
			# a little bit of jitter
			launch_basis = launch_basis.rotated(Vector3.UP, randfn(0,1) * spread_jitter)
			launch_basis = launch_basis.rotated(Vector3.RIGHT, randfn(0,1) * height_jitter)
			projectile.global_basis = launch_basis
			
			# initial velocity
			var direction := launch_basis * Vector3.MODEL_FRONT * projectile.speed
			projectile.apply_impulse(direction)
			
			# optional effect
			if attack_effect:
				attack_effect.start()
			
			# enabled
			projectile.fire_start()
			
			if projectile_count > 0:
				projectile_count -= 1


## Starts the attack effect and enables the AttackComponent if set.
## Will reset the cooldown, but doesn't prevent the attack
func attack_start():
	reset_cooldown()
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


#region Tooling

func _process(_delta: float):
	if Engine.is_editor_hint():
		if _dummy_arrow:
			_dummy_arrow.global_position = launch_point.global_position

func _on_inspector_edited_object_changed(property: StringName):
	super._on_inspector_edited_object_changed(property)
	if property == &"projectile_scene":
		_rebuild_dummy_arrow()

var _dummy_arrow: Projectile = null
func _rebuild_dummy_arrow():
	if Engine.is_editor_hint():
		if _dummy_arrow:
			_dummy_arrow.queue_free()
		if projectile_scene:
			_dummy_arrow = projectile_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
			add_child(_dummy_arrow)
			_dummy_arrow.position = launch_point.position
#endregion
	
