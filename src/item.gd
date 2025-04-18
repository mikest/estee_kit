# Copyright (c) 2024-2025 M. Estee
# MIT License

##
## Item is a class for creating RigidBody3D objects that characters can interact with.
##
## Item has physics, can be picked-up, thrown, dropped, put in inventory, worn, or used.
## It works with the [InventoryComponent].
##
## Items have a type field which can be used to change their behavior, or control what
## [ItemSlot] they attach to.
## [br][br]
## [img]res://addons/estee_kit/docs/example_item.png[/img]

@icon("../icons/bag-icon.png")
class_name Item
extends RigidBody3D

# Item times. UNARMED is no-item and should only be used for fists, etc.
enum Type {
	UNARMED,	## Intangable. Can't be picked up or thrown
	ITEM,		## Generic object. Can be thrown, dropped or used.
	MELEE_1H,	## One handed weapons. Swords, etc.
	MELEE_2H,	## Two handed weapons.
	RANGED_1H,	## Crossbows, staffs, wands
	RANGED_2H,	## Cannons, Heavy Crossbows.
	PROJECTILE,	## Things fired from other weapons.
	ACCESSORY,	## Things which the character can equip, like armor or capes.
}

# Physics enabled, detached from user
signal on_will_drop(item: Item)	## About to be dropped. Still in inventory.
signal on_dropped(item: Item)	## Has been dropped. Back in world.

## The item's display name. Can be used in Inventory.
@export var item_name: String = "Item"

## The items type. Determines various behaviors
@export var type: Type = Type.ITEM

## The rate at which we can interact with the object
@export var cooldown: float = .25

## Orientation of the item when in displayed in a UI inventory.
@export var inventory_front: Vector3 = Vector3.MODEL_FRONT

## Can this item be thrown?
@export var throwable := true

## When an item is carried, physics are disabled. The attached collision shapes
## are also disabled.
@export var carried: bool = false:
	get: return freeze
	set(val):
		freeze = val
		var collisions := find_children("*", "CollisionShape3D", true)
		for collision: CollisionShape3D in collisions:
			collision.disabled = val


## An optional glint overlay that is applied to the Geometry Overlay Material for all [MeshInstance3D]
@export var optional_glint_overlay: ShaderMaterial = preload("../materials/glint.tres")

## When an item is on cooldown it can't be used.
var can_use: bool:
	get: return _cooldown.is_stopped()

## Utility getter for unarmed type items.
var is_unarmed: bool:
	get: return type == Item.Type.UNARMED

## Utility getter for melee type items.
var is_melee: bool:
	get: return type == Item.Type.RANGED_2H or type == Item.Type.MELEE_2H

## Utility getter for ranged type items.	
var is_ranged: bool:
	get: return type == Item.Type.RANGED_1H or type == Item.Type.RANGED_2H

## Utility getter for projectile type items.
var is_projectile: bool:
	get: return type == Item.Type.PROJECTILE

## Utility getter for generic items.
var is_item: bool:
	get: return type == Item.Type.ITEM

## Utility getter for accessory items.
var is_accessory: bool:
	get: return type == Item.Type.ACCESSORY


#region Runtime
## Internal timer for cooldown. Reset when used or dropped.
var _cooldown: Timer = null


## Call [code]super._ready()[/code] if you sublass.
func _ready() -> void:
	# cooldown timer
	_cooldown = Timer.new()
	_cooldown.one_shot = true
	add_child(_cooldown)
	
	# Apply the optional glint shader to all meshes
	if optional_glint_overlay:
		_add_glint_overlay()
	
	body_entered.connect(_on_body_entered)


## Call [code]super._ready()[/code] if you sublass.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			if is_inside_tree():
				_parented()
			else:
				_parented.call_deferred(true)
		
		NOTIFICATION_UNPARENTED:
			_unparented()
	

## Enables and disables physics when moving from inventory to level.
func _parented(_deferred:bool = false) -> void:
	# Enable physics when we're in the top level
	var parent := get_parent()
	if parent == _get_level():
		carried = false
	else:
		# Disable physics if we're added to an inventory
		carried = true


## Currently a no-op
func _unparented():
	pass


## Despawns the item if it falls off the map.
func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		# despawn if we fall off the map
		if global_position.y < -100.0:
			queue_free()
			push_warning("Dropped out of world, despawning ", self)
#endregion


## Optional styling to make interactable items easier to spot in scene.
func _add_glint_overlay():
	var meshes := find_children("*", "MeshInstance3D")
	for node in meshes:
		var mesh: MeshInstance3D = node
		mesh.material_overlay = optional_glint_overlay
		
		# set the depth pass for each sub-material so overlay renders correctly when picked up
		# by character
		if mesh.get_surface_override_material_count() > 0:
			var mat: StandardMaterial3D = mesh.get_active_material(0) as StandardMaterial3D
			if mat:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS


## Get the extents of this object
func get_aabb() -> AABB:
	var bounds: AABB
	var meshes := find_children("*", "MeshInstance3D")
	for mesh: MeshInstance3D in meshes:
		bounds = bounds.merge(mesh.get_aabb())
	
	return bounds

#region Equip/Unequip mechanics
#func _get_level() -> Level:
	#if is_inside_tree():
		#var main: Main = get_tree().current_scene
		#return main.level as Level
	#else:
		#return null

## Returns the "world" object. Customize for your purposes.
func _get_level() -> Node3D:
	if is_inside_tree():
		return get_tree().current_scene
	else:
		return null

## Returns the transform for this object when held. Add a [Marker3D] named "Handle" to the scene
## for custom handle locations and orientations. Otherwise origin will be used.
func get_handle_transform() -> Transform3D:
	var node: Node3D = get_node_or_null("Handle") as Node3D
	if node:
		return node.transform
	else:
		return Transform3D.IDENTITY

func _on_body_entered(_body: Node):
	# currently a no-op for all but Projectile
	pass
#endregion


#region Actions and States
## Items are interactable if they're not on cooldown
var can_pickup: bool:
	get: return not carried and _cooldown and _cooldown.is_stopped()

## Call by owner when an item is dropped.
func drop_item():
	assert(carried, "Can't drop uncarried item!")
	if carried:
		on_will_drop.emit(self)
		reparent(_get_level())
		_cooldown.start(cooldown)
		on_dropped.emit(self)

#endregion
