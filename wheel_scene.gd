extends Node3D
# Standard European Roulette sequence
signal numrolled(roll)
var wheel_numbers = [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]
#connect signals for hovering and clicking
# This list stores any active charm resources you've picked up
var active_charms: Array = []

func _ready():
	for child in get_children():
		if child.has_signal("object_clicked"):
			child.object_hovered.connect(_on_object_hovered)
			child.object_unhovered.connect(_on_object_unhovered)
			child.object_clicked.connect(_on_object_clicked)

# Logic:
func apply_to_wheel(wheel):
	var blacks = [2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35]
	return wheel.filter(func(n): return n in blacks or n == 0)

# Logic:
func apply_to_wheel_1(wheel):
	var evens = wheel.filter(func(n): return n % 2 == 0 and n != 0)
	wheel.append_array(evens)
	return wheel

# Logic:
func apply_to_roll(roll):
	if roll == 0:
		print("Panic! Re-rolling...")
		return wheel_numbers.pick_random()
	return roll

func spin_wheel():
	# 1. Create a temporary copy of the wheel so we don't permanently break the game
	var modified_wheel = wheel_numbers.duplicate()
	
	# 2. Apply "Pool Modifiers" (e.g., adding extra 7s, removing 0s)
	for charm in active_charms:
		if charm.has_method("apply_to_wheel"):
			modified_wheel = charm.apply_to_wheel(modified_wheel)
	
	# 3. Pick the initial result
	var roll = modified_wheel.pick_random()
	
	# 4. Apply "Result Overrides" (e.g., re-rolling if the house wins)
	for charm in active_charms:
		if charm.has_method("apply_to_roll"):
			roll = charm.apply_to_roll(roll)
			roll = int(roll)
	return roll

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

	# Logic for clicking the bowl (the "Play" button)
	if node.item_info.item_name == "bowl":
		print("--- SPINNING ---")
		var result = spin_wheel()
		emit_signal("numrolled",result)
		print("Result: ", result)
	
	# Logic for picking up a charm (simulating Balatro shop)
	elif node.item_info.item_name == "Lucky Clover":
		# Example: Add an anonymous charm object directly
		var clover = {
			"apply_to_roll": func(r): return 7 if r == 0 else r # Turns 0 into 7
		}
		active_charms.append(clover)
		print("Added Lucky Clover: House 0s are now 7s!")
