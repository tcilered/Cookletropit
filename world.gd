extends Node3D

@export var table_square_scene: PackedScene
var bet = 0
var bet_placed = false
var roll_recived = int()

func _pysics_process():
	pass

func _ready():
	# Loop through all the children in this scene
	for child in get_children():
		# Check if this child is one of our interactive objects
		if child.has_signal("object_clicked"):
			# Connect the child's custom signals to functions in THIS script
			child.object_hovered.connect(_on_object_hovered)
			child.object_unhovered.connect(_on_object_unhovered)
			child.object_clicked.connect(_on_object_clicked)
		# Loop through all children to find the squares dynamically.
	# This assumes your squares are grouped under a node, or just children of the board.
	# Adjust the path to wherever your individual Area3D squares live.
	var board_container = $Table_Scene
	
	for child in board_container.get_children():
		if child is Area3D: # Safety check to ensure it's a square
			# Connect each signal to a matching function in this script
			child.placing_requested.connect(_on_square_placing_requested)
			child.hover_entered.connect(_on_square_hover_entered)
			child.hover_exited.connect(_on_square_hover_exited)
			child.hover_moved.connect(_on_square_hover_moved)

# --- Receiver Functions ---

func _on_object_hovered(node):
	print("Main World: hovering in: ", node.name)
	
	# We check if 'item_info' is assigned before trying to read it
	if node.item_info:
		print("This item is called ", node.item_info.item_name, " and is worth ", node.item_info.item_value)

func _on_object_unhovered(node):
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



# --- SIGNAL RECEIVERS ---

# Triggered when a player left-clicks a zone/square
func _on_square_placing_requested(play_type: String, origin_square_id: int, global_spawn_pos: Vector3) -> void:
	print("World received PLACE BET: ", play_type, " from Square ", origin_square_id)
	

	if bet_placed == false:
		var new_chip = table_square_scene.instantiate()
		bet_placed = true
		bet = origin_square_id
		add_child(new_chip)
		new_chip.global_position = global_spawn_pos
		
	# TODO: Deduck money from player balance, add to total bet pool, etc.

# Triggered when the mouse first crosses into a square's boundary
func _on_square_hover_entered(square_id: int) -> void:
	# Great place to trigger a generic highlight or sound effect
	pass

# Triggered when the mouse completely leaves a square
func _on_square_hover_exited(square_id: int) -> void:
	# Clean up highlight visuals here
	pass

# Triggered when the mouse moves across internal zones (e.g. center -> top edge)
func _on_square_hover_moved(play_type: String, origin_square_id: int, global_pos: Vector3) -> void:
	# Great place to move a "ghost/preview chip" around so players see 
	# exactly what bet they are highlighting before clicking!
	pass


func _on_wheel_scene_numrolled(roll: Variant) -> void:
	roll_recived = roll
	print(roll_recived)
	if roll_recived == bet:
		print("you won")
