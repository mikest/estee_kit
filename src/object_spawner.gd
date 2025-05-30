# Copyright (c) 2024-2025 M. Estee
# MIT License

@icon("../icons/ring-icon.png")
extends Node3D
class_name ObjectSpawner

##
## For creating objects at random spawn points when signaled.
## Add Marker3D objects as children to create a spawn point for the scene.
##
## Needs a "world" layer to spawn them into anda navigation region.
##

@export var scene: PackedScene = null
@export var max_spawn: int = 3
@export_range(1,100) var units_per_spawn: int = 1
@export var mean := 0
@export var deviation := .1

@export var height_offset: float = 0 # Height above the floor that scene should spawn
@export var navigation_region: NavigationRegion3D ## region objects can spawn into
@export_flags_3d_physics var world_collision_mask: int = 1	## layers that objects can spawn onto


var ray: RayCast3D = null
var _should_spawn: bool = false
const ray_dist := 1000.0		# casting distance for finding "ground"


#region Runtime
func _ready():
	assert(scene, "Object Spawner is missing scene")
	assert(navigation_region, "Object Spawner is nav region")
	
	# create a ray caster for finding the ground
	ray = RayCast3D.new()
	ray.target_position.y = -ray_dist # far
	ray.collision_mask = world_collision_mask
	add_child(ray)
	
	# count existing children in nav region and add that to our max
	max_spawn = max_spawn + navigation_region.get_child_count()


# only spawn during process
func _process(_delta: float):
	if _should_spawn:
		_spawn_scene()
#endregion


func _spawn_scene() -> Array[Node3D]:
	var instances: Array[Node3D] = []
	var spawn_point: = self.global_position
	
	# if we have marker children, use a random one as a spawn point
	var markers := find_children("*", "Marker3D")
	if markers:
		var idx := randi() % markers.size()
		spawn_point = (markers[idx] as Marker3D).global_position
	
	for n in units_per_spawn:
		var count := navigation_region.get_child_count()
		if count < max_spawn:
			# find the resting position for the new enemy
			ray.global_position.x = spawn_point.x
			ray.global_position.z = spawn_point.z
			ray.global_position.y = ray_dist/2.0
			
			# test ray cast with new position
			ray.force_update_transform()
			ray.force_raycast_update()
			if ray.is_colliding():
				spawn_point.y = ray.get_collision_point().y + height_offset + randfn(mean, deviation)
				
				var instance := scene.instantiate() as Node3D
				navigation_region.add_child(instance)
				
				instance.global_position = spawn_point
				instance.rotate_y(randf_range(-TAU, TAU))
				instance.position.x += randfn(mean, deviation)
				instance.position.z += randfn(mean, deviation)
				
				# add to list
				instances.push_back(instance)
		else:
			print("Too many nav children, max_spawn exceeded.")
	
	# clear spawn flag
	_should_spawn = false
	return instances


func on_spawn(_switch):
	_should_spawn = true
