@tool
extends EditorPlugin

const Attack = preload("src/attack.gd")
const AttackComponent = preload("src/attack_component.gd")
const HealthComponent = preload("src/health_component.gd")

const InventoryComponent = preload("src/inventory_component.gd")
const Item = preload("src/item.gd")
const ItemSlot = preload("src/item_slot.gd")

const Weapon = preload("src/weapon.gd")
const Bomb = preload("src/bomb.gd")
const Projectile = preload("src/projectile.gd")
const ProjectileLauncher = preload("src/projectile_launcher.gd")

const Effect = preload("src/effect.gd")

const ObjectSpawner = preload("src/object_spawner.gd")
const PathFollower = preload("src/path_follower.gd")

const TriggerComponent = preload("src/trigger_component.gd")

const Utils = preload("src/utils.gd")


const BagIcon = preload("icons/bag-icon.png")
const DebugIcon = preload("icons/debug-icon.png")
const EyeIcon = preload("icons/eye-icon.png")
const HandIcon = preload("icons/hand-icon.png")
const HeartIcon = preload("icons/heart-icon.png")
const ProjectileIcon = preload("icons/projectile-icon.png")
const RingIcon = preload("icons/ring-icon.png")
const SwordIcon = preload("icons/sword-icon.png")


func _enable_plugin() -> void:
	add_custom_type("Attack", "Node", Attack, SwordIcon)
	add_custom_type("AttackComponent", "Area3D", AttackComponent, SwordIcon)
	add_custom_type("HealthComponent", "Area3D", HealthComponent, HeartIcon)
	
	add_custom_type("InventoryComponent", "Node3D", InventoryComponent, BagIcon)
	add_custom_type("Item", "RigidBody3D", Item, BagIcon)
	add_custom_type("ItemSlot", "RemoteTransform3D", ItemSlot, HandIcon)
	
	add_custom_type("Weapon", "Item", Weapon, SwordIcon)
	add_custom_type("Bomb", "Weapon", Bomb, SwordIcon)
	add_custom_type("Projectile", "Weapon", Projectile, ProjectileIcon)
	add_custom_type("ProjectileLauncher", "Node3D", ProjectileLauncher, ProjectileIcon)
	
	add_custom_type("Effect", "Node3D", Effect, RingIcon)
	
	add_custom_type("ObjectSpawner", "Node3D", ObjectSpawner, RingIcon)
	add_custom_type("PathFollower", "Path3D", PathFollower, RingIcon)
	
	add_custom_type("TriggerComponent", "Area3D", TriggerComponent, EyeIcon)
	
	add_custom_type("Utils", "Object", Utils, HeartIcon)


func _disable_plugin() -> void:
	remove_custom_type("Attack")
	remove_custom_type("AttackComponent")
	remove_custom_type("HealthComponent")
	
	remove_custom_type("InventoryComponent")
	remove_custom_type("Item")
	remove_custom_type("ItemSlot")
	
	remove_custom_type("Weapon")
	remove_custom_type("Bomb")
	remove_custom_type("Projectile")
	remove_custom_type("ProjectileLauncher")
	
	remove_custom_type("Effect")
	
	remove_custom_type("ObjectSpawner")
	remove_custom_type("PathFollower")
	
	remove_custom_type("TriggerComponent")
	
	remove_custom_type("Utils")
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
