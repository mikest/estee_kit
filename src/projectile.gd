@icon("../icons/projectile-icon.png")
extends Weapon
class_name Projectile

enum Hit {
	Stick,
	Bounce,
	Expire
}

@export var speed: float = 50.0
@export var expiration_time: float = 10.0	# Max time, min time is half this. Zero is "never expires"
@export var hit_cooldown: float = 1.0 # Delay befor projectile attack disables after hitting
@export var hit_type: Hit = Hit.Stick

@export var hit_effect: Effect
@export var expire_effect: Effect

var _expired:bool = false
var _expired_timer: Timer = null

var _remote_transform: = RemoteTransform3D.new()	# not attached until we hit something.

func _ready() -> void:
	super._ready()
	_expired_timer = Timer.new()
	add_child(_expired_timer)
	_expired_timer.one_shot = true
	_expired_timer.connect("timeout", on_expired)
	
	# for collisions
	contact_monitor = true
	continuous_cd = true		# we're a fast moving small object
	max_contacts_reported = 1
	
	# Already registered by Weapon...
	# body_entered.connect(_on_body_entered)
	if type != Item.Type.PROJECTILE:
		push_warning("Item ", name, " type is not PROJECTILE!")

func _on_body_entered(body: Node):
	super._on_body_entered(body)
	
	# random expiration time
	if expiration_time > 0:
		_expired_timer.start(randf_range(expiration_time/2,expiration_time))

	# stop physics, stop monitoring
	if hit_type == Hit.Stick:
		freeze = true
	
		# attach to collider, delete projectile if collider exits
		body.add_child(_remote_transform)
		
		_remote_transform.global_transform = global_transform
		_remote_transform.remote_path = _remote_transform.get_path_to(self)
		_remote_transform.tree_exited.connect(queue_free)
	
		# cancel out any forces we might impart
		linear_velocity = Vector3.ZERO
	
	# hit effects and sounds
	if hit_effect:
		hit_effect.start()
	
	# stop after a cooldown delay
	if hit_cooldown > 0:
		await get_tree().create_timer(hit_cooldown).timeout
	attack_stop()

func on_expired():
	if _expired:
		if expire_effect:
			expire_effect.stop()
		queue_free()
	else:
		# NOTE: clear the remote_transform so it doesn't
		# override our _handle_expiring animation!
		_remote_transform.remote_path = ""
		_expired = true
		contact_monitor = false
		freeze = false
		
		# stop the hit effect when starting expire
		if hit_effect:
			hit_effect.stop()
		if expire_effect:
			expire_effect.start()
		
		# apply a small amount of angular torque towards gravity
		apply_torque(Vector3(-45,0,0))
		
		# start the timer again, but this time we free when we expire
		if expiration_time > 0:
			_expired_timer.start(randf_range(expiration_time/2,expiration_time))
