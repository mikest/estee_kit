# Copyright (c) 2024-2025 M. Estee
# MIT License

@icon("../icons/bag-icon.png")
class_name Item
extends RigidBody3D

##
## A mixin class for things that the user can pick up, equip and throw
##
## Works with InventoryComponent to create items like weapons and other objects.
##

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
signal on_will_drop(item: Item)	## Dropped, and implicitly unequipped
signal on_dropped(item: Item)	## Dropped, and implicitly unequipped
#signal on_throw(item: Item)	## Launched, implicit unequipped

@export var item_name: String = "Item"

## The items type. Determines various behaviors
@export var type: Type = Type.ITEM

## The rate at which we can interact with the object
@export var cooldown: float = .25  # delay between allowable interactions

## Orientation of the item when in inventory
@export var inventory_front: Vector3 = Vector3.MODEL_FRONT

## Can this item be thrown?
@export var throwable := true

## When an item is carried, physics are disabled.
@export var carried: bool = false:
	get: return freeze
	set(val):
		freeze = val
		var collisions := find_children("*", "CollisionShape3D", true)
		for collision: CollisionShape3D in collisions:
			collision.disabled = val

var can_use: bool:
	get: return _cooldown.is_stopped()

# shortcuts
var is_unarmed: bool:
	get: return type == Item.Type.UNARMED
	
var is_melee: bool:
	get: return type == Item.Type.RANGED_2H or type == Item.Type.MELEE_2H
	
var is_ranged: bool:
	get: return type == Item.Type.RANGED_1H or type == Item.Type.RANGED_2H

var is_projectile: bool:
	get: return type == Item.Type.PROJECTILE

var is_item: bool:
	get: return type == Item.Type.ITEM


#region Runtime
var _cooldown: Timer = null

# the object that should manage callbacks
func _ready() -> void:
	# cooldown timer
	_cooldown = Timer.new()
	_cooldown.one_shot = true
	add_child(_cooldown)
	
	body_entered.connect(_on_body_entered)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			if is_inside_tree():
				_parented()
			else:
				_parented.call_deferred(true)
		
		NOTIFICATION_UNPARENTED:
			_unparented()
	

func _parented(_deferred:bool =false) -> void:
	# Enable physics when we're in the top level
	var parent := get_parent()
	if parent == _get_level():
		carried = false
	else:
		# Disable physics if we're added to an inventory
		carried = true


# Remove ourselves from inventory if we move to a new parent
func _unparented():
	pass


func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		# despawn if we fall off the map
		if global_position.y < -100.0:
			queue_free()
			push_warning("Dropped out of world, despawning ", self)
#endregion

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

func _get_level() -> Node3D:
	if is_inside_tree():
		return get_tree().current_scene
	else:
		return null

func get_handle_transform() -> Transform3D:
	var node: Node3D = get_node_or_null("Handle") as Node3D
	if node:
		return node.transform
	else:
		return Transform3D.IDENTITY

func _on_body_entered(_body: Node):
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
