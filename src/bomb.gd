
##
## A specialization of Weapon
##
class_name Bomb
extends Weapon

@export_range(0, 10, 0.01, "hide_slider", "suffix:sec") var fuse_delay: float = 2
@export var fuse_effect: Effect				## Start when fuse is lit. Optional.
@export var fuse_health: HealthComponent	## Attack to light fuse. Optional.
@export var bomb_mesh: Node3D				## Hidden when the explosion starts. Optional

@export_subgroup("Explosion Attack")
@export_range(0, 10, 0.01, "hide_slider", "suffix:sec") var attack_duration: float = 2
@export var attack_scale_curve: Curve

var bomb_timer: Timer
var delay_fuse: bool = true


func _ready():
	super._ready()
	
	# for fuse and explosion
	bomb_timer = Timer.new()
	bomb_timer.one_shot = true
	add_child(bomb_timer)
	bomb_timer.timeout.connect(_on_bomb_timer)
	
	if fuse_health:
		fuse_health.on_died.connect(attack_start)
	
	# don't start out attacking
	attack_stop()
	fuse_stop()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var attack_min_scale := 0.05
	
	# scale the size of our attack area during an attack
	if is_attacking:
		# clip the phase to a minimum scale so colliders don't get sad
		var phase: float = 1.0 - maxf(attack_min_scale, bomb_timer.time_left / bomb_timer.wait_time)
		if attack_scale_curve:
			phase = attack_scale_curve.sample(phase)
		attack_component.scale = Vector3(phase,phase,phase)
	else:
		attack_component.scale = Vector3(attack_min_scale, attack_min_scale, attack_min_scale)


func _on_body_entered(_body: Node):
	super._on_body_entered(_body)


func _on_bomb_timer():
	# fuse expired, start explosion
	if delay_fuse:
		delay_fuse = false
		bomb_timer.start(attack_duration)
		fuse_stop()
		super.attack_start()
		
		# hide the bomb object because at this point, it has "exploded"
		if bomb_mesh:
			bomb_mesh.hide()
		if fuse_health:
			fuse_health.disabled = true
	
	# explosion ended, expire
	else:
		# disable the attack without triggering the end of attack so we don't
		# reset the explosion animation before it finishes.
		attack_component.enabled = false
		
		if attack_effect and attack_effect.is_playing:
			await attack_effect.finished

		# full stop
		super.attack_stop()
		queue_free()


func fuse_start():
	if fuse_effect:
		fuse_effect.start()


func fuse_stop():
	if fuse_effect:
		fuse_effect.stop()


func attack_start():
	# cancel out weapon's attack start, we light the fuse instead
	bomb_timer.start(fuse_delay)
	delay_fuse = true
	fuse_start()


func attack_stop():
	super.attack_stop()
