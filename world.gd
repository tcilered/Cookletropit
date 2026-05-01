extends Node3D

func _ready():
	# Loop through all the children in this scene
	for child in get_children():
		# Check if this child is one of our interactive objects
		if child.has_signal("object_clicked"):
			# Connect the child's custom signals to functions in THIS script
			child.object_hovered.connect(_on_object_hovered)
			child.object_unhovered.connect(_on_object_unhovered)
			child.object_clicked.connect(_on_object_clicked)

# --- Receiver Functions ---

func _on_object_hovered(node):
	print("Main World: hovering over: ", node.name)
	
	# We check if 'item_info' is assigned before trying to read it
	if node.item_info:
		print("This item is called ", node.item_info.item_name, " and is worth ", node.item_info.item_value)

func _on_object_unhovered(node):
	if node.item_info:
		print("Main World: stopped hovering over: ", node.item_info.item_name)

func _on_object_clicked(node):
	# Unconditional print so you know the World heard the signal
	print("Main World detected a click on an object!")
	
	if node.item_info != null:
		print("Main World says the item is: ", node.item_info.item_name)
	else:
		print("Main World says: This object has no ItemData resource assigned!")
