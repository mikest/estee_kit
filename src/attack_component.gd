# Copyright (c) 2024-2025 M. Estee
# MIT License

@icon("../icons/sword-icon.png")
extends Area3D
class_name AttackComponent

##
## A class for managing a collision shape that can hit a HealthComponent.
##
## Will detect bodies that have HealthComponent's attached and do damage to them.
## NOTE: HealthComponent is expected to be at the root of an Area3D or CharacterBody3D
##
## Call attack_start to enable the ability to do damage, and attack_stop when
## the attack ability has concluded. During that time, this component
## will do damage to all HealthComponents it collides with.
##
## Damage will occure at cooldown rate until stopped, unless one_shot is enabled.
## Damage can occure to multiple HealthComponents at during attack.
##
## The HealthComponent also has a cooldown, and will prevent attacks during
## that phase.

signal on_attack_start()	## Emitted at the start of an attack
signal on_attack(damage: Attack)	## Emitted when attacking a HealthComponent
signal on_attack_stop()	## Emitted at the end of an attack.

@export var one_shot: bool ## Hit once per swing, or continuously?
@export var damage: Attack 	## Damage done when invoked.
@export var start_enabled: bool

## Updates monitoring and the disabled flag for all collider children
## so they aren't visible in the debugger.
var enabled: bool:
	get: return monitoring
	set(val):
		process_mode = Node.PROCESS_MODE_INHERIT if val else Node.PROCESS_MODE_DISABLED
		set_deferred("monitoring", val) #monitoring = val
		Utils.enable_collisions(self, val)

var _cooldown_timer: Timer = null
var _attack_bodies: Dictionary[Node3D, HealthComponent] = {}


## Utility for finding the health component in a standard place
static func get_health(body:Node3D) -> HealthComponent:
	if body:
		return body.find_child("HealthComponent", false) as HealthComponent
	else:
		return null


func _ready() -> void:
	# Not detectable by other areas or bodies
	set_deferred("monitorable", false) #monitorable = false
	
	# Attacks repeat after cooldown if still hitting health area
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	add_child(_cooldown_timer)
	_cooldown_timer.timeout.connect(_on_cooldown)
	
	# NOTE: Does not detect other areas.
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)

	Utils.set_collision_debug(self, Color.ORANGE_RED, true)
	enabled = start_enabled


func _on_cooldown():
	# do damage again to all overlappers.
	if not one_shot and _attack_bodies.size():
		for health: HealthComponent in _attack_bodies.values():
			attack(health)


## Call to enable the area for attacking health
func attack_start():
	_cooldown_timer.start(damage.cooldown)
	enabled = true
	on_attack_start.emit()


## First attack, add to cooldown set
func _on_entered(body: Node3D):
	# exclude our owner
	if not body.is_ancestor_of(self):
		# does this object have a HealthComponent?
		var health := get_health(body)
		if health:
			_attack_bodies[body] = health
			attack(health)


## Exited, remove from cooldown set
func _on_exited(body: Node3D):
	# exclude ourself
	if body != get_parent_node_3d():
		if _attack_bodies.has(body):
			_attack_bodies.erase(body)
	pass


## Do the attack on the health component.
func attack(health: HealthComponent):
	if health and damage:
		# make a copy of our damage template, and update the dynamic props
		var new_attack: Attack = damage.duplicate()
		new_attack.attack_position = global_position
		new_attack.attack_direction = global_position.direction_to(health.global_position)
		
		# do the damage
		health.damage(new_attack)
		on_attack.emit(new_attack)
		
		if not one_shot:
			_cooldown_timer.start(damage.cooldown)


## Done attacking, disable the attack area and clear out any stale attacks
func attack_stop():
	enabled = false
	_attack_bodies.clear()
	on_attack_stop.emit()
