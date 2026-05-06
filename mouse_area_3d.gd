extends Area3D

# The Resource that holds all this item's specific data
@export var item_info: ItemData 

# Define custom signals that carry the object (self) to the main world
signal object_hovered(interacted_node)
signal object_unhovered(interacted_node)
signal object_clicked(interacted_node)

func _ready():
	# Connect Godot's built-in mouse signals to our own functions
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)
	if item_info != null and item_info.item_mesh != null:
		$Collision/Mesh.mesh = item_info.item_mesh
		$Collision/Mesh.mesh.material.albedo_texture = item_info.surface_texture
		# 2. Regenerate the collision shape from that mesh
		var new_shape = item_info.item_mesh.create_convex_shape()
		$Collision.shape = new_shape
func _on_mouse_entered():
	object_hovered.emit(self)

func _on_mouse_exited():
	object_unhovered.emit(self)

func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	# Check for a left mouse click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 1. Unconditional print so you ALWAYS know the click registered
		print("Area3D was clicked!") 
		
		# 2. Check if the resource is there
		if item_info != null:
			print(" -> Attached Resource: ", item_info.item_name)
		else:
			print(" -> WARNING: item_info is empty! Drag a .tres file into the Inspector.")
			
		# 3. Emit the signal to the world regardless
		object_clicked.emit(self)
