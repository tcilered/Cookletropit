extends Node3D

# Emitted when a player clicks a charm in the shop.
# The listener (world.gd) handles the gold deduction and charm activation.
signal charm_purchase_requested(item_node)

func _ready() -> void:
	_connect_item_signals(self)

# Recursively walks descendants and connects object_clicked on any Area3D
# interactive items found inside the shop options.
func _connect_item_signals(node: Node) -> void:
	for child in node.get_children():
		if child.has_signal("object_clicked"):
			if not child.object_clicked.is_connected(_on_item_clicked):
				child.object_clicked.connect(_on_item_clicked)
		_connect_item_signals(child)

func _on_item_clicked(node: Node) -> void:
	charm_purchase_requested.emit(node)
