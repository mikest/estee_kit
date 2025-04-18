# Copyright (c) 2024-2025 M. Estee
# MIT License

@icon("../icons/bag-icon.png")
extends Node3D
class_name InventoryComponent

##
## A class for managing an inventory in 3D space.
##
## It add Item nodes to include them in inventory. Has a notion of a "selected"
## item, and a mechanism for updating positions when added and removed.
##

signal on_selection_change()
signal on_add_item(item: Item)
signal on_remove_item(item: Item)

var _selected: int = 0
var _open: bool = false


var is_empty: bool:
	get: return get_child_count() == 0


var is_open: bool:
	get: return _open


#region Runtime
func _init() -> void:
	if Engine.is_editor_hint(): return
	
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)


func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	# update all the slot positions
	_update_item_positions()
#endregion


#region Ownership Changes
func _on_child_entered_tree(node: Node):
	var item: Item = node as Item
	if item:
		# update all the slot positions
		_on_item_added(item)
		_selection_change()
		
		# update the item positions on the next round the loop
		# so that the transofrms will stick.
		_update_item_positions.call_deferred()
		on_add_item.emit(item)
	else:
		#push_error("Attempting to add non-Item to Inventory!", node)
		pass


func _on_child_exiting_tree(node: Node):
	var item: Item = node as Item
	if item:
		_deferred_child_exited(item)


func _deferred_child_exited(item: Item):
	_on_item_removed(item)
	if item == selected_item():
		_selected = -1
		_selection_change()
	
	_update_item_positions()
	on_remove_item.emit(item)
	print_rich(self.name, " removed [color=orange]", item,"[/color]")
#endregion


#region Subclass Callbacks
## To be overloaded by derived classes to do something when an Item is added.
func _on_item_added(_item: Item):
	pass

## To be overloaded by derived classes to do something when an Item is removed.
func _on_item_removed(_item: Item):
	pass

## To be overloaded by derived classes for custom positioning
func _update_item_position(item: Item, _index: int, _count: int):
	item.transform = Transform3D.IDENTITY


## To be overloaded by derived classes for custom selection actions
func _selection_change():
	pass
#endregion


# Called when the slot count changes
func _update_item_positions():
	var items := get_children()
	for index in items.size():
		var item: Item = items[index]
		_update_item_position(item, index, items.size())
	
	if not is_inside_tree():
		print("Item not in tree!")


func selected_item() -> Item:
	var items := get_children()
	if items and _selected >= 0 and (_selected < items.size()):
		return items[_selected] as Item
	else:
		return null
	

func select_item(item: Item):
	if item and is_ancestor_of(item):
		_selected = item.get_index()
		_selection_change()
		on_selection_change.emit()
	else:
		push_warning("Couldn't select item! ", item)


func select_none():
	_selected = -1
	_selection_change()
	on_selection_change.emit()


func select_next():
	var items := get_children()
	if items:
		_selected = wrapi(_selected + 1, 0, items.size())
		_selection_change()
		on_selection_change.emit()


func select_prev():
	var items := get_children()
	if items:
		_selected = wrapi(_selected - 1, 0, items.size())
		_selection_change()
		on_selection_change.emit()


func open_inventory():
	_open = true


func close_inventory():
	_open = false
