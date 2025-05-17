# Copyright (c) 2024-2025 M. Estee
# MIT License

extends Object
class_name Utils

# our layer indexes
const WorldLayer := 1
const PlayerLayer := 2
const ItemLayer := 3
const EnemyLayer := 4
const InteractionLayer := 5


static func default_gravity() -> Vector3:
	var gravity_magnitude : float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var gravity : Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
	return gravity * gravity_magnitude


static var _layer_name_cache: Dictionary[String, int] = {}
static func get_layer_from_name(name: String) -> int:
	if _layer_name_cache.size() == 0:
		for idx in range(32):
			var path := "layer_names/3d_physics/layer_" + str(idx+1)
			var layer_name = ProjectSettings.get_setting(path)
			if layer_name:
				_layer_name_cache[layer_name] = 1 << idx
	
	if name in _layer_name_cache:
		return _layer_name_cache[name]
	
	return 0


## Return the distance from node to a target node
static func distance_to_target(node: Node3D, target: Node3D) -> float:
	return node.global_position.distance_to(target.global_position)


## Return a point that is `distance` away from `target`
static func offset_from_target(node: Node3D, target: Node3D, distance: float) -> Vector3:
	var dir = -node.global_position.direction_to(target.global_position) * distance
	return dir + target.global_position


## Returns a point that is rotated `radians` around a target node
static func rotate_around_target(node: Node3D, target: Node3D, angle: float) -> Vector3:
	var pos = target.to_local(node.global_position)
	pos = target.to_global(pos.rotated(Vector3.UP, angle))
	return pos


static func align_transform_with_yaxis(xform: Transform3D, y_axis: Vector3):
	xform.basis.y = y_axis
	xform.basis.x = -xform.basis.z.cross(y_axis)
	xform.basis = xform.basis.orthonormalized()
	return xform


# Used to figure out when the IKTarget has strayed too far and we should start a step cycle
static func is_point_outside_ellipse(point: Vector2, origin: Vector2, h_size: float, v_size: float) -> bool:
	var theta := point.angle_to(origin) + PI*2
	var dx := point.x - origin.x
	var dy := point.y - origin.y
	var xt2 := dx * cos(theta) - dy * sin(theta)
	var yt2 := dx * sin(theta) + dy * cos(theta)
	return (xt2**2 / h_size**2 + yt2**2 / v_size**2) > 1


static func render_circle(instance: MeshInstance3D, pos: Vector3, dia: float, color: Color, segments: int = 24, axis: Vector3 = Vector3.UP):
	var mesh: ImmediateMesh = instance.mesh
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, instance.material_override)
	for n in segments+1:
		var angle := wrapi(n,0,segments) * 2 * PI / segments
		var pt := Vector3.MODEL_FRONT.rotated(axis, angle)
		
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(pt * dia + pos)
	mesh.surface_end()


static func render_ellipse(instance: MeshInstance3D, pos: Vector3, x_size: float, z_size: float, color: Color, segments: int = 24 ):
	var mesh: ImmediateMesh = instance.mesh
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, instance.material_override)
	for n in segments + 1:
		var theta: float = (PI * 2.0) * (n/float(segments))
		
		var x := x_size * cos(theta)  # X coordinates
		var z := z_size * sin(theta)  # Y coordinates
	
		mesh.surface_set_color(color)
		
		var pt := Vector3(x,0,z) + pos
		mesh.surface_add_vertex(pt)
	mesh.surface_end()


static func render_points(instance: MeshInstance3D, pts: Array[Vector3], color: Color):
	var mesh: ImmediateMesh = instance.mesh
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, instance.material_override)
	for pt in pts:
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(pt)
	mesh.surface_end()


## Return the signed angular distance to a local point in the XZ plane
static func get_xz_signed_angle_to_local_point(local_pos: Vector3) -> float:
	return Basis.looking_at(local_pos, Vector3.UP, true).get_euler().y


## Return the angular difference between an old and new basis
static func get_angular_difference(old_basis: Basis, new_basis: Basis) -> Vector3:
	var old_quat: Quaternion = old_basis.get_rotation_quaternion()
	var new_quat: Quaternion = new_basis.get_rotation_quaternion()
	var diff_quat: Quaternion = new_quat * old_quat.inverse()
	return diff_quat.get_euler()


## Update the angular and linear velocities for static bodies based on an old and a new transform
static func update_constant_velocities(bodies: Array[Node], old_transform: Transform3D, new_transform: Transform3D, delta: float):
	var angular_diff = Utils.get_angular_difference(old_transform.basis, new_transform.basis)
	var constant_velocity = (new_transform.origin - old_transform.origin) * 1.0/delta
	var constant_rotation = angular_diff * 1.0/delta
	for body in bodies:
		(body as StaticBody3D).constant_linear_velocity = constant_velocity
		(body as StaticBody3D).constant_angular_velocity = constant_rotation


## Calculate the mesh bounds for a tree of nodes.
static func get_mesh_bounds(parent: Node, exclude_top_level_transform: bool=true) -> AABB:
	var bounds : AABB = AABB()
	if parent is MeshInstance3D:
		bounds = (parent as VisualInstance3D).get_aabb();

	for i in range(parent.get_child_count()):
		var child : Node = parent.get_child(i)
		if child:
			var child_bounds : AABB = get_mesh_bounds(child, false)
			if bounds.size == Vector3.ZERO && parent:
				bounds = child_bounds
			else:
				bounds = bounds.merge(child_bounds)

	if bounds.size == Vector3.ZERO && !parent:
		bounds = AABB(Vector3(-0.2, -0.2, -0.2), Vector3(0.4, 0.4, 0.4))

	var parent_node3d: Node3D = parent as Node3D
	if !exclude_top_level_transform and parent_node3d:
		bounds = parent_node3d.transform * bounds

	return bounds


## Update the debug settings on a collection of collision shapes
static func set_collision_debug(node: Node3D, color: Color, fill: bool):
	var collisions := node.find_children("*", "CollisionShape3D", true)
	assert(collisions, "Missing collisions")
	for collision: CollisionShape3D in collisions:
		collision.debug_color = color
		collision.debug_fill = fill


## Toggle the enable state on a collection of collisions
static func enable_collisions(node: Node3D, enabled: bool, recursive: bool = true):
	var collisions := node.find_children("*", "CollisionShape3D", recursive)
	assert(collisions, "Missing collisions")
	for collision: CollisionShape3D in collisions:
		collision.disabled = not enabled
		collision.debug_fill = enabled
