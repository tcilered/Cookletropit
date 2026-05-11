extends Node3D
# Standard European Roulette sequence
var wheel_numbers = [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]
#connect signals for hovering and clicking
func _ready():
	# Loop through all the children in this scene
	for child in get_children():
		# Check if this child is one of our interactive objects
		if child.has_signal("object_clicked"):
			# Connect the child's custom signals to functions in THIS script
			child.object_hovered.connect(_on_object_hovered)
			child.object_unhovered.connect(_on_object_unhovered)
			child.object_clicked.connect(_on_object_clicked)
			
func spin_wheel():
	var roll = wheel_numbers.pick_random()
	return roll

func _on_object_hovered(node):
	print("Main World: hovering in: ", node.name)
	node.scale = Vector3(2,2,2)
	# We check if 'item_info' is assigned before trying to read it
	if node.item_info:
		print("This item is called ", node.item_info.item_name, " and is worth ", node.item_info.item_value)

func _on_object_unhovered(node):
	node.scale = Vector3(1,1,1)
	print("Main World: stopped hovering in: ", node.name)
	if node.item_info:
		print("Main World: stopped hovering over: ", node.item_info.item_name)

func _on_object_clicked(node):
	# Unconditional print so you know the World heard the signal
		
	print("Main World detected a click on an object!")
	if node.item_info != null:
		print("Main World says the item is: ", node.item_info.item_name)
			
	else:
		print("Main World says: This object has no ItemData resource assigned!")
	if node.item_info.item_name == "bowl":
			# Call your spin function (make sure it's accessible)
			print("rolling!!")
			print(spin_wheel())
