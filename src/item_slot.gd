# Copyright (c) 2024-2025 M. Estee
# MIT License

@icon("../icons/hand-icon.png")
extends RemoteTransform3D
class_name ItemSlot

##
## A class for optionally positioning an Item class object by its "Handle"
##
## This works a little like RemoteTransform and is intended to be a child of
## a BoneAttachment. If the "Handle" Marker is not present the items origin
## will be used instead.
##
## Update the remote_path to the item you want to attach to the parent bone
## by its handle.
##
## Example tree structure:
## Skeleton
##	+ BoneAttachment 
##		+ ItemSlot
##
## Elsewhere...
## 	lefthand_melee: ItemSlot = get_left_hand()
## 	lefthand_melee.remote_path = get_path_to_node(my_sword)
##

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		if remote_path:
			var item := get_node_or_null(remote_path) as Item
			if item:
				item.transform = item.transform * item.get_handle_transform().inverse()
	pass
