# Copyright (c) 2024-2025 M. Estee
# MIT License

@icon("../icons/sword-icon.png")
extends Resource
class_name Attack

##
## A class for representing an attack.
##

@export var cooldown: float = 0.2						## Delay between uses
@export var attack_damage: float = 25					## Damage units. 100 is 1 <3
@export var knockback_force: float = 100				## Knockback force
@export var attack_position: Vector3 = Vector3.ZERO		## Contact point
@export var attack_direction: Vector3 = Vector3.ZERO	## Vector direction of attack
