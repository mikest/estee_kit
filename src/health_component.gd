# Copyright (c) 2024-2025 M. Estee
# MIT License

@icon("../icons/heart-icon.png")
extends CollisionShape3D
class_name HealthComponent

##
## A class for managing a collision shape that can be hit by DamageComponent.
##
## Lives inside something that can be collided with, like
## an Area3D or a CharacterBody3D.
##
## Handles the notions of being hit, knock back, and a cooldown period.
## By convention, 100 HP is "one heart".

## Emmitted when component is out of health. Health can be negative.
signal on_died()

## Emmitted when health changes, for any reason
signal on_health_changed(percent: float)

## Emmitted when health changes, for any reason
signal on_healed(amount: float)

## Emitted when an AttackComponent does damage to this Component.
signal on_attacked(attack: Attack)

## Emitted in response to damage if our KNOCKBACK_THRESHOLD is exce
signal on_knockback(scale: float)

## When attacked, this timer will decay with a phase from [0..1]
## you can use it to drive juicing animations, like a "flash" effect.
##
## Emitted from _physics_process.
signal on_hit_flash(phase: float)

## Emitted when the attack from damage has concluded the hit_flash phase
signal on_attack_finished()

## Duration for the "being hit" phase.
@export_range(0.1, 3, 0.1) var cooldown: float = 0.3

## Maximum health, acts as a limit on heal()
## There is no minimum health
@export var max_health := 100.0

## Damage threashold before on_knockback() will be emitted.
@export var knockback_threshold: float = 150

## Maximum scale of knockback, regardless of how hard we where hit.
@export var max_knockback: float = 250

@export_subgroup("Debug")

#@export_custom(PROPERTY_HINT_NONE, "hint", PROPERTY_USAGE_DEFAULT) var debug_color

const HP_PER_HEART: float = 100.0

var health: float 	## Hitpoints. 100 is one heart, by convention.
var is_dead: bool:	## Are we in the afterlife?
	get: return health <= 0.0

# for hit flashes
var _hit_timer : Timer

func _ready():
	debug_color = Color.WEB_GREEN
	debug_fill = true
	
	# initial health
	health = max_health
	
	# set up the decay timer
	_hit_timer = Timer.new()
	_hit_timer.one_shot = true
	add_child(_hit_timer)
	_hit_timer.timeout.connect(_on_hit_timer)

var _previous_phase: float = 0
func _physics_process(_delta: float) -> void:
	## hit flashes
	var phase: float = _hit_timer.time_left/ _hit_timer.wait_time
	if phase != _previous_phase:
		if _hit_timer.time_left:
			on_hit_flash.emit(phase)
		else:
			on_hit_flash.emit(0)
	_previous_phase = phase

func get_health() -> float:
	return health

func get_max_health() -> float:
	return max_health

func set_health(new_health: float):
	var old_health := health
	health = max(new_health,0)
	
	# no signal on no change
	if health != old_health:
		on_health_changed.emit(health/max_health)
		
		# you only die once
		if health <= 0:
			on_died.emit()

## Sum up all the attack directions and apply the kockback force.
## Return the resulting movement change
func knockback_for_attacks(attacks: Array[Attack]) -> Vector3:
	var velocity: Vector3 = Vector3.ZERO
	if attacks.size():
		# sum up the attacks
		for attack in attacks:
			velocity += attack.attack_direction * attack.knockback_force
		
		# if the knockback exceeds a threshold, trigger the animation
		if velocity.length() > knockback_threshold:
			var knockback_scale := clampf(velocity.length()/max_knockback, 0, 1)
			on_knockback.emit(knockback_scale)
	
	return velocity

## Call to heal. No cooldown limit.
func heal(amount: float):
	on_healed.emit(amount)
	set_health(health + amount)

## Call to do damage. Will do nothing if cooldown has not expired.
func damage(attack: Attack):
	if _hit_timer.is_stopped():
		on_attacked.emit(attack)
		set_health(health - attack.attack_damage)
		_hit_timer.start(cooldown)

func _on_hit_timer():
	on_attack_finished.emit()
