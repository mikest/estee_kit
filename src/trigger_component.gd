# Copyright (c) 2024-2025 M. Estee
# MIT License

@tool
@icon("../icons/eye-icon.png")
class_name TriggerComponent
extends Area3D

##
## A mixin class for things that the user can trigger
##
## Area could be an enemy or the player. Masks control which.
##

## Emitted when a character collides with us
signal on_trigger(user: Node3D)
signal on_triggered()	## same as above, but with no user

## The rate at which we can interact with the object
@export var trigger_cooldown: float = .25  # delay between allowable on_interact invocations
@export var trigger_delay: float = 0.5	# delay before trigger fires

var _triggered: bool = false

## Updates monitoring and the disabled flag for all collider children
## so they aren't visible in the debugger.
var enabled: bool:
	get: return monitoring
	set(val):
		monitoring = val
		Utils.enable_collisions(self, val)

var _cooldown: Timer = null


# the object that should manage callbacks
func _ready() -> void:
	# We're undetectable
	monitorable = false
	collision_layer = 0
	
	# cooldown timer
	_cooldown = Timer.new()
	_cooldown.one_shot = true
	add_child(_cooldown)
	
	body_entered.connect(trigger)
	enabled = true
	_triggered = false
	
	Utils.set_collision_debug(self, Color.GOLDENROD, false)


## Items are interactable if they're not on cooldown
var can_interact: bool:
	get: return enabled and _cooldown.is_stopped()


# Called by Interactor when this area wanders into their interacting area
func trigger(user: Node3D):
	# NOTE: don't trigger for our parent
	if can_interact and not user.is_ancestor_of(self):
		await get_tree().create_timer(trigger_delay).timeout
		on_trigger.emit(user)
		on_triggered.emit()
		_cooldown.start(trigger_cooldown)
