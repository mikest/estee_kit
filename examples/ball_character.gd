extends CharacterBody3D


var _velocity: Vector3

func _physics_process(_delta):
	velocity = lerp(velocity, _velocity, _delta)
	move_and_slide()

func _unhandled_input(event):
	_velocity.x = Input.get_axis("ui_left", "ui_right") * 10
	_velocity.z = Input.get_axis("ui_up", "ui_down") * 10
	
	if event.is_action_pressed("ui_select"):
		_velocity.y = 5
	else:
		_velocity.y = Utils.default_gravity().y
	
	#if event.is_action_pressed("ui_select"):
		#if 
		


func _on_health_component_on_health_changed(percent):
	%HitPoints.text = str(percent)


func _on_health_component_on_died():
	%HitPoints.text = "Dead."


func _on_interaction_area_body_entered(body):
	var weapon: Weapon = body as Weapon
	if weapon:
		weapon.attack_start.call_deferred()
