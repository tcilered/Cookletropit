extends Node3D

# Standard European Roulette sequence
signal numrolled(roll)
var active_charms: Array = []
# --- Roulette Data ---
var wheel_numbers = [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]
var blacks = [2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35]
var reds = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
var evens = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36]
var odds = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35]
var lows = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]   
var highs = [19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36] 
var first_dozen = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
var second_dozen = [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
var third_dozen = [25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36]
var first_column = [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31, 34]
var second_column = [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35]
var third_column = [3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36]
var square_numbers = [0, 1, 4, 9, 16, 25, 36]

# --- Game State ---
# This list stores any active charm resources you've picked up


func _ready():
	for child in get_children():
		if child.has_signal("object_clicked"):
			child.object_hovered.connect(_on_object_hovered)
			child.object_unhovered.connect(_on_object_unhovered)
			child.object_clicked.connect(_on_object_clicked)


# --- Core Logic ---
func spin_wheel():
	# 1. Create a temporary copy of the wheel so we don't permanently break the game
	var modified_wheel = wheel_numbers.duplicate()
	
	# 2. Apply "Pool Modifiers" (e.g., adding extra numbers)
	for charm in active_charms:
		if typeof(charm) == TYPE_DICTIONARY and charm.has("apply_to_wheel"):
			# In Godot 4, you use .call() to execute a Callable stored in a Dictionary
			modified_wheel = charm.apply_to_wheel.call(modified_wheel)
	
	# 3. Pick the initial result
	var roll = modified_wheel.pick_random()
	
	# 4. Apply "Result Overrides" (e.g., turning 0s into 7s)
	for charm in active_charms:
		if typeof(charm) == TYPE_DICTIONARY and charm.has("apply_to_roll"):
			roll = charm.apply_to_roll.call(roll)
			
	return int(roll)


# --- Charm Management ---
func add_charm(charm_name: String):
	var new_charm = {}
	
	if charm_name == "Lucky Clover":
		new_charm = {
			"name": charm_name,
			"apply_to_roll": func(r): return 7 if r == 0 else r 
		}
		print("Added Lucky Clover: House 0s are now 7s!")
		
	elif charm_name == "The Cube":
		new_charm = {
			"name": charm_name,
			"apply_to_wheel": func(w): 
				for i in range(3):
					w.append_array(square_numbers)
				return w
		}
		print("Added The Cube: Added 3 sets of square numbers to the wheel!")
		
	else:
		# If it doesn't match "Lucky Clover" or "The Cube", it falls back here
		new_charm = {"name": charm_name}
		print("Warning: No custom logic found for '", charm_name, "'. Adding as generic charm.")
		
	active_charms.append(new_charm)
	GlobalData.active_charms_global = active_charms
	# 3. Clean print out of your active inventory
	var charm_names = active_charms.map(func(c): return c.get("name", "Unknown"))
	print("Active charms list is now: ", charm_names)


# --- Signal Handling ---
func _on_object_hovered(node):
	node.scale = Vector3(1.2, 1.2, 1.2) # Adjusted scale for subtler feedback
	if node.item_info:
		print("Hovering: ", node.item_info.item_name)

func _on_object_unhovered(node):
	node.scale = Vector3(1, 1, 1)

func _on_object_clicked(node):
	if not node.item_info:
		return

	var item_name = node.item_info.item_name

	# Logic for clicking the bowl (the "Play" button)
	if item_name == "bowl":
		print("--- SPINNING ---")
		var result = spin_wheel()
		numrolled.emit(result)
		print("Result: ", result)
	
	# Logic for picking up a charm
	else:
		add_charm(item_name)

func _on_node_3d_main_world_item_toggeled(item: Variant) -> void:
	if item and item.item_info:
		add_charm(item.item_info.item_name)
